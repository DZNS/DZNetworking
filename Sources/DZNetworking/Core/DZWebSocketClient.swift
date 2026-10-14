import Foundation

// MARK: - DZWebSocketClient
/// An actor that manages a persistent WebSocket connection, providing
/// request-response pairing, auto-reconnection, ping loops, and
/// routing for unsolicited events.
public actor DZWebSocketClient {
  /// Represents the current connection state of the WebSocket.
  public enum SocketState: Sendable {
    /// The socket is disconnected and will not attempt to reconnect.
    case disconnected
    /// The socket is currently attempting its initial connection.
    case connecting
    /// The socket is successfully connected and can send/receive messages.
    case connected
    /// The socket was disconnected unexpectedly and is attempting to reconnect.
    case reconnecting
  }
  
  private let url: URL
  private let headers: [String: String]
  private let urlSession: URLSession
  
  private var webSocketTask: URLSessionWebSocketTask?
  private var delegate: WebSocketDelegate?
  
  /// Callback invoked whenever raw data is received.
  public private(set) var onDataReceived: (@Sendable (Data) -> Void)?

  /// Callback invoked whenever the connection state changes.
  ///
  /// Calls arrive in order, one at a time. Each call uses the handler that was set when the state changed.
  /// Do not block inside the handler or wait for a later call, because later calls wait for it to return.
  public private(set) var onStateChange: (@Sendable (SocketState) -> Void)?
  
  /// Callback invoked on connection error or close, passing the error and HTTP response.
  public private(set) var onError: (@Sendable (Error?, HTTPURLResponse?) -> Void)?
  
  public func setHandlers(
    onStateChange: (@Sendable (SocketState) -> Void)? = nil,
    onDataReceived: (@Sendable (Data) -> Void)? = nil,
    onError: (@Sendable (Error?, HTTPURLResponse?) -> Void)? = nil
  ) {
    if onStateChange != nil { self.onStateChange = onStateChange }
    if onDataReceived != nil { self.onDataReceived = onDataReceived }
    if onError != nil { self.onError = onError }
  }

  
  /// The current connection state of the client.
  public private(set) var state: SocketState = .disconnected {
    didSet {
      let newState = state
      if oldValue != newState, let handler = onStateChange {
        // Each callback waits for the previous one, so states arrive in order
        stateTask = Task { [previous = stateTask] in
          await previous?.value
          handler(newState)
        }
      }
    }
  }

  // Continuations for threads waiting for the connection to be established
  private var connectionContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
  
  // Pending requests mapped by their eventId
  private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]
  
  // Registered handlers for unsolicited events
  // Dictionary mapping `eventName` to a dictionary of UUIDs to type-erased closures
  private var eventHandlers: [String: [UUID: @Sendable (Data) throws -> Void]] = [:]
  
  private var pingTask: Task<Void, Never>?
  private var receiveTask: Task<Void, Never>?
  // Waits before the next reconnection attempt
  private var reconnectTask: Task<Void, Never>?
  // Last state callback, so the next one can wait for it
  private var stateTask: Task<Void, Never>?
  
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  private let reconnectionPolicy: ReconnectionPolicy?
  private var reconnectionAttempt: UInt = 0
  private let pingInterval: TimeInterval?

  private static let disconnectedError = NSError(domain: "DZWebSocketClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebSocket disconnected"])

  /// Initializes a new WebSocket client.
  ///
  /// - Parameters:
  ///   - url: The URL of the WebSocket server.
  ///   - headers: Extra HTTP headers sent with each connection attempt.
  ///   - urlSession: The `URLSession` to use for creating the underlying WebSocket task. Defaults to `.shared`.
  ///   - encoder: A `JSONEncoder` used to encode outgoing messages. Defaults to a standard `JSONEncoder`.
  ///   - decoder: A `JSONDecoder` used to decode incoming messages. Defaults to a standard `JSONDecoder`.
  ///
  ///   - reconnectionPolicy: How to retry after the connection drops. With `nil`, the client retries every
  ///     2 seconds until `disconnect()` is called. A successful connection resets the attempt count.
  ///
  /// The client pings the server every 10 seconds while connected.
  /// To limit how long a connection attempt may stay silent, set `timeoutIntervalForRequest` on the
  /// `URLSessionConfiguration` before creating the session. It is an inactivity timeout, so it restarts whenever data arrives.
  public init(url: URL, headers: [String: String] = [:], urlSession: URLSession = .shared, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder(), reconnectionPolicy: ReconnectionPolicy? = nil) {
    self.init(url: url, headers: headers, urlSession: urlSession, encoder: encoder, decoder: decoder, reconnectionPolicy: reconnectionPolicy, pingInterval: 10)
  }

  /// Initializes a new WebSocket client with a custom ping interval.
  ///
  /// - Parameter pingInterval: Seconds between pings while connected, from 1 second to 1 day. Pass `nil` to turn pings off.
  public init(url: URL, headers: [String: String] = [:], urlSession: URLSession = .shared, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder(), reconnectionPolicy: ReconnectionPolicy? = nil, pingInterval: TimeInterval?) {
    if let pingInterval {
      precondition((1...86_400).contains(pingInterval), "pingInterval must be between 1 second and 1 day")
    }

    self.url = url
    self.headers = headers
    self.urlSession = urlSession
    self.encoder = encoder
    self.decoder = decoder
    self.reconnectionPolicy = reconnectionPolicy
    self.pingInterval = pingInterval
  }

  deinit {
    reconnectTask?.cancel()
    pingTask?.cancel()
    receiveTask?.cancel()
    webSocketTask?.cancel(with: .goingAway, reason: nil)
  }
  
  /// Connects to the WebSocket server.
  ///
  /// If the client is already connected or in the process of connecting, this method does nothing.
  /// If the client is waiting to reconnect, it reconnects right away without resetting the attempt count.
  /// Calling this method transitions the state to `.connecting` and resumes pending operations once successful.
  /// The client keeps reconnecting after a drop until the policy gives up or `disconnect()` is called,
  /// even if every waiting send is cancelled.
  public func connect() {
    guard state == .disconnected || (state == .reconnecting && reconnectTask != nil) else {
      return
    }

    reconnectTask?.cancel()
    reconnectTask = nil

    let isReconnecting = state == .reconnecting
    state = isReconnecting ? .reconnecting : .connecting
    
    var request = URLRequest(url: url)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    let task = urlSession.webSocketTask(with: request)
    webSocketTask = task
    
    // Each callback passes its own task, so callbacks from an old connection are ignored
    let sessionDelegate = WebSocketDelegate(
      onOpen: { [weak self] task in
        Task {
          await self?.handleDidOpen(task)
        }
      },
      onClose: { [weak self] task, _, _ in
        Task {
          await self?.handleDidClose(task)
        }
      },
      onComplete: { [weak self] task, error, response in
        Task { [weak self] in
          // Errors are always reported, even from an old connection
          if let handler = await self?.onError {
            handler(error, response)
          }
          await self?.handleDidClose(task, error: error)
        }
      }
    )
    
    self.delegate = sessionDelegate
    task.delegate = sessionDelegate
    task.resume()
  }
  
  private func handleDidOpen(_ task: URLSessionWebSocketTask) {
    guard task === webSocketTask,
          state == .connecting || state == .reconnecting,
          reconnectTask == nil else {
      return
    }

    state = .connected
    reconnectionAttempt = 0
    
    for continuation in connectionContinuations.values {
      continuation.resume()
    }
    connectionContinuations.removeAll()
    
    startReceiving()
    startPinging()
  }
  
  private func handleDidClose(_ task: URLSessionTask, error: Error? = nil) {
    guard task === webSocketTask else {
      return
    }

    handleDisconnection(error: error)
  }
  
  /// Disconnects from the WebSocket server and cancels all pending tasks.
  ///
  /// Sends waiting for a connection and requests waiting for a response fail with a
  /// "WebSocket disconnected" error. The connection state transitions to `.disconnected`.
  public func disconnect() {
    state = .disconnected
    reconnectionAttempt = 0
    reconnectTask?.cancel()
    reconnectTask = nil
    pingTask?.cancel()
    pingTask = nil
    receiveTask?.cancel()
    receiveTask = nil
    
    webSocketTask?.cancel(with: .normalClosure, reason: nil)
    webSocketTask = nil
    
    failPendingRequests(with: Self.disconnectedError)
    
    for continuation in connectionContinuations.values {
      continuation.resume(throwing: Self.disconnectedError)
    }
    connectionContinuations.removeAll()
  }
  
  /// Waits until the WebSocket is connected and returns its task.
  ///
  /// If the client is disconnected, this starts a connection attempt.
  /// While reconnecting, it keeps waiting. It throws if the caller is cancelled or the client disconnects.
  private func connectedTask() async throws -> URLSessionWebSocketTask {
    try Task.checkCancellation()

    if state != .connected {
      if state == .disconnected {
        connect()
      }

      let id = UUID()
      try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
          if Task.isCancelled {
            continuation.resume(throwing: CancellationError())
          }
          else {
            connectionContinuations[id] = continuation
          }
        }
      } onCancel: {
        Task {
          await self.cancelConnectionWait(id: id)
        }
      }
    }

    // The connection can drop again before this caller resumes
    try Task.checkCancellation()
    guard state == .connected, let task = webSocketTask else {
      throw Self.disconnectedError
    }
    return task
  }
  
  /// Sends a payload to the WebSocket server and waits for a specific response.
  ///
  /// - Parameters:
  ///   - message: The payload to send, conforming to `WebSocketEvent`.
  ///   - responseType: The expected `Decodable` type of the response.
  /// If the client is disconnected, this starts a connection attempt first, even after `disconnect()`.
  /// Use a new `eventId` for every request. Do not reuse one, even after a request was cancelled or failed.
  ///
  /// - Throws: Any encoding/decoding errors, networking errors, `CancellationError` if the caller is cancelled,
  ///   or a "WebSocket disconnected" error if the connection drops before the response arrives.
  public func send<T: WebSocketEvent, U: Decodable & Sendable>(message: T, responseType: U.Type) async throws -> U {
    let task = try await connectedTask()
    
    let eventId = message.eventId
    let data = try encoder.encode(message)
    
    let responseData: Data = try await withTaskCancellationHandler {
      return try await withCheckedThrowingContinuation { continuation in
        // Register before sending, so a cancellation always finds the request
        if Task.isCancelled {
          continuation.resume(throwing: CancellationError())
          return
        }
        pendingRequests[eventId] = continuation

        task.send(.data(data)) { [weak self] error in
          if let error {
            Task {
              await self?.failPendingRequest(eventId: eventId, error: error)
            }
          }
        }
      }
    } onCancel: {
      Task {
        await self.cancelPendingRequest(eventId: eventId)
      }
    }
    
    return try decoder.decode(U.self, from: responseData)
  }
  
  /// Sends a payload to the WebSocket server without waiting for a specific response (fire-and-forget).
  ///
  /// - Parameter message: The payload to send, conforming to `WebSocketEvent`.
  /// If the client is disconnected, this starts a connection attempt first, even after `disconnect()`.
  /// Cancelling stops the send only if it has not started yet. A message that has started sending cannot be taken back.
  ///
  /// - Throws: Any encoding errors, networking errors, `CancellationError`, or a "WebSocket disconnected" error.
  public func send<T: WebSocketEvent>(message: T) async throws {
    let task = try await connectedTask()
    
    let data = try encoder.encode(message)
    try Task.checkCancellation()
    try await task.send(.data(data))
  }
  
  /// Sends raw data over the WebSocket. Behaves like `send(message:)`.
  public func send(data: Data) async throws {
    let task = try await connectedTask()
    try await task.send(.data(data))
  }
  
  /// Sends a raw string over the WebSocket. Behaves like `send(message:)`.
  public func send(string: String) async throws {
    let task = try await connectedTask()
    try await task.send(.string(string))
  }
  
  /// Registers a handler for unsolicited server events that match a specific event name.
  ///
  /// - Parameters:
  ///   - event: The name of the event to listen for (matched against the root `event` JSON property).
  ///   - type: The expected `Decodable` payload type for this event.
  ///   - handler: A closure that will be invoked when the event is received and successfully decoded.
  /// - Returns: A `UUID` representing the handler, which can be used to remove it later.
  @discardableResult
  public func addHandler<T: Decodable & Sendable>(for event: String, type: T.Type, handler: @escaping @Sendable (String, T) -> Void) -> UUID {
    let decoder = self.decoder
    let id = UUID()
    let typeErased: @Sendable (Data) throws -> Void = { data in
      let decoded = try decoder.decode(T.self, from: data)
      handler(event, decoded)
    }
    eventHandlers[event, default: [:]][id] = typeErased
    return id
  }
  
  /// Removes a specific handler by its UUID.
  ///
  /// - Parameters:
  ///   - id: The UUID of the handler to remove.
  ///   - event: The name of the event it was registered for.
  public func removeHandler(id: UUID, for event: String) {
    eventHandlers[event]?.removeValue(forKey: id)
  }
  
  /// Removes all previously registered handlers for a specific event name.
  ///
  /// - Parameter event: The name of the event whose handlers should be removed.
  public func removeAllHandlers(for event: String) {
    eventHandlers.removeValue(forKey: event)
  }
  
  /// Returns an `AsyncStream` that yields incoming events for a specific event name.
  ///
  /// This is an alternative to `addHandler` that natively supports Swift Concurrency.
  /// The stream removes its internal handler when it is cancelled or finished.
  /// A registered stream can keep the client alive until that cleanup removes the handler.
  /// Stopping iteration alone does not guarantee that cleanup.
  ///
  /// - Parameters:
  ///   - event: The name of the event to listen for.
  ///   - type: The expected `Decodable` payload type for this event.
  /// - Returns: An `AsyncStream` yielding decoded payloads of type `T`.
  public nonisolated func listen<T: Decodable & Sendable>(for event: String, type: T.Type) -> AsyncStream<T> {
    return AsyncStream { continuation in
      Task {
        let handlerId = await self.addHandler(for: event, type: type) { _, payload in
          continuation.yield(payload)
        }
        
        continuation.onTermination = { @Sendable _ in
          Task {
            await self.removeHandler(id: handlerId, for: event)
          }
        }
      }
    }
  }
  
  // MARK: - Internal Loops
  
  private func startReceiving() {
    receiveTask?.cancel()
    guard let task = webSocketTask else { return }
    // Holds the client weakly, so an unused client can be released
    receiveTask = Task { [weak self] in
      while !Task.isCancelled {
        // The delegate's handleDidClose / handleDidComplete will trigger the reconnection.
        guard let message = try? await task.receive() else { break }
        guard await self?.deliver(message, from: task) == true else { break }
      }
    }
  }

  /// Handles a received message and returns whether the receive loop should continue.
  private func deliver(_ message: URLSessionWebSocketTask.Message, from task: URLSessionWebSocketTask) -> Bool {
    // Ignore messages from an old connection
    guard !Task.isCancelled, task === webSocketTask else { return false }
    handleIncomingMessage(message)
    return true
  }
  
  private struct Envelope: Decodable {
    let eventId: String?
    let event: String?
  }
  
  private func handleIncomingMessage(_ message: URLSessionWebSocketTask.Message) {
    let data: Data
    switch message {
    case .data(let d):
      data = d
    case .string(let s):
      guard let d = s.data(using: .utf8) else {
        return
      }
      data = d
    @unknown default:
      return
    }
    
    onDataReceived?(data)
    
    do {
      let envelope = try decoder.decode(Envelope.self, from: data)
      
      // Check if this is a response to a pending request
      if let eventId = envelope.eventId, let continuation = pendingRequests[eventId] {
        pendingRequests.removeValue(forKey: eventId)
        continuation.resume(returning: data)
        return
      }
      
      // Otherwise, check if it's an unsolicited event
      if let event = envelope.event, let handlers = eventHandlers[event] {
        for handler in handlers.values {
          do {
            try handler(data)
          }
          catch {
            print("DZWebSocketClient: Handler failed for event '\(event)': \(error)")
          }
        }
      }
      
    }
    catch {
      if onDataReceived == nil {
        print("DZWebSocketClient: Failed to process incoming message: \(error)")
      }
    }
  }
  
  private func handleDisconnection(error: Error? = nil) {
    // Skip if a retry is already scheduled for this failure
    guard state != .disconnected, reconnectTask == nil else {
      return
    }

    state = .reconnecting
    pingTask?.cancel()
    pingTask = nil
    receiveTask?.cancel()
    receiveTask = nil
    // Keep the cancelled task so callbacks from it can still be matched and ignored
    webSocketTask?.cancel()
    // Their responses cannot arrive on a new connection
    failPendingRequests(with: error ?? Self.disconnectedError)
    
    let delay: TimeInterval
    if let policy = reconnectionPolicy {
      reconnectionAttempt += 1
      delay = policy.nextWaitInterval(for: reconnectionAttempt)
      
      if delay == .greatestFiniteMagnitude {
        disconnect()
        return
      }
    }
    else {
      delay = 2
    }
    
    reconnectTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(delay))
      // Stop if connect() or disconnect() cancelled the wait
      guard !Task.isCancelled else { return }
      await self?.retry()
    }
  }

  /// Starts the next attempt unless this wait was cancelled.
  private func retry() {
    // A cancelled wait must not start a new attempt
    guard !Task.isCancelled, state == .reconnecting else { return }
    connect()
  }
  
  private func startPinging() {
    pingTask?.cancel()
    pingTask = nil
    guard let interval = pingInterval else { return }

    pingTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(interval))
        guard !Task.isCancelled, await self?.sendPing() == true else { break }
      }
    }
  }
  
  /// Sends a ping and returns whether the ping loop should continue.
  private func sendPing() -> Bool {
    // Stop if this loop was cancelled or the connection is gone
    guard !Task.isCancelled, state == .connected, let task = webSocketTask else { return false }
    task.sendPing { [weak self] error in
      if let error = error {
        print("DZWebSocketClient: Ping failed: \(error)")
        // Force disconnect so reconnect loop handles it
        Task { [weak self] in
          await self?.handleDidClose(task, error: error)
        }
      }
    }
    return true
  }
  
  // MARK: - Dictionary Helpers
  
  private func failPendingRequests(with error: Error) {
    for continuation in pendingRequests.values {
      continuation.resume(throwing: error)
    }
    pendingRequests.removeAll()
  }

  private func cancelConnectionWait(id: UUID) {
    connectionContinuations.removeValue(forKey: id)?.resume(throwing: CancellationError())
  }
  
  private func failPendingRequest(eventId: String, error: Error) {
    if let continuation = pendingRequests.removeValue(forKey: eventId) {
      continuation.resume(throwing: error)
    }
  }
  
  private func cancelPendingRequest(eventId: String) {
    if let continuation = pendingRequests.removeValue(forKey: eventId) {
      continuation.resume(throwing: CancellationError())
    }
  }
}

// MARK: - WebSocketEvent
/// A protocol that every outgoing WebSocket message must conform to.
///
/// By conforming to this protocol, the WebSocket client can extract the `eventId`
/// to correlate request and response payloads automatically.
public protocol WebSocketEvent: Encodable & Sendable {
  /// A unique identifier for the event. Used to match responses to requests.
  /// Use a new value for every request, even when sending the same content again.
  var eventId: String { get }
}

// MARK: - WebSocketDelegate
private final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate, Sendable {
  let onOpen: @Sendable (URLSessionWebSocketTask) -> Void
  let onClose: @Sendable (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode, Data?) -> Void
  let onComplete: @Sendable (URLSessionTask, Error?, HTTPURLResponse?) -> Void

  init(onOpen: @escaping @Sendable (URLSessionWebSocketTask) -> Void,
       onClose: @escaping @Sendable (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode, Data?) -> Void,
       onComplete: @escaping @Sendable (URLSessionTask, Error?, HTTPURLResponse?) -> Void) {
    self.onOpen = onOpen
    self.onClose = onClose
    self.onComplete = onComplete
  }

  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    onOpen(webSocketTask)
  }

  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    onClose(webSocketTask, closeCode, reason)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    onComplete(task, error, task.response as? HTTPURLResponse)
  }
}
