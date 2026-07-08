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
      if oldValue != newState {
        Task { [onStateChange] in
          onStateChange?(newState)
        }
      }
    }
  }

  // Continuations for threads waiting for the connection to be established
  private var connectionContinuations: [CheckedContinuation<Void, Never>] = []
  
  // Pending requests mapped by their eventId
  private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]
  
  // Registered handlers for unsolicited events
  // Dictionary mapping `eventName` to a dictionary of UUIDs to type-erased closures
  private var eventHandlers: [String: [UUID: @Sendable (Data) throws -> Void]] = [:]
  
  private var pingTask: Task<Void, Never>?
  private var receiveTask: Task<Void, Never>?
  
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  private let reconnectionPolicy: ReconnectionPolicy?
  private var reconnectionAttempt: UInt = 0

  /// Initializes a new WebSocket client.
  ///
  /// - Parameters:
  ///   - request: The `URLRequest` to connect to.
  ///   - urlSession: The `URLSession` to use for creating the underlying WebSocket task. Defaults to `.shared`.
  ///   - encoder: A `JSONEncoder` used to encode outgoing messages. Defaults to a standard `JSONEncoder`.
  ///   - decoder: A `JSONDecoder` used to decode incoming messages. Defaults to a standard `JSONDecoder`.
  public init(url: URL, headers: [String: String] = [:], urlSession: URLSession = .shared, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder(), reconnectionPolicy: ReconnectionPolicy? = nil) {
    self.url = url
    self.headers = headers
    self.urlSession = urlSession
    self.encoder = encoder
    self.decoder = decoder
    self.reconnectionPolicy = reconnectionPolicy
  }
  
  /// Connects to the WebSocket server.
  ///
  /// If the client is already connected or in the process of connecting, this method does nothing.
  /// Calling this method transitions the state to `.connecting` and resumes pending operations once successful.
  public func connect() {
    guard state == .disconnected || state == .reconnecting else {
      return
    }

    let isReconnecting = state == .reconnecting
    state = isReconnecting ? .reconnecting : .connecting
    
    var request = URLRequest(url: url)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    webSocketTask = urlSession.webSocketTask(with: request)
    
    let sessionDelegate = WebSocketDelegate(
      onOpen: { [weak self] in
        Task {
          await self?.handleDidOpen()
        }
      },
      onClose: { [weak self] _, _ in
        Task {
          await self?.handleDidClose()
        }
      },
      onComplete: { [weak self] error, response in
        Task { [weak self] in
          if let handler = await self?.onError {
            handler(error, response)
          }
          await self?.handleDidClose()
        }
      }
    )
    
    self.delegate = sessionDelegate
    webSocketTask?.delegate = sessionDelegate
    webSocketTask?.resume()
  }
  
  private func handleDidOpen() {
    guard state == .connecting || state == .reconnecting else {
      return
    }

    state = .connected
    reconnectionAttempt = 0
    
    for continuation in connectionContinuations {
      continuation.resume()
    }
    connectionContinuations.removeAll()
    
    startReceiving()
    startPinging()
  }
  
  private func handleDidClose() {
    guard state != .disconnected else {
      return
    }

    handleDisconnection()
  }
  
  /// Disconnects from the WebSocket server and cancels all pending tasks.
  ///
  /// Calling this method cancels any in-flight requests by throwing a cancellation error
  /// to their waiting continuations. The connection state transitions to `.disconnected`.
  public func disconnect() {
    state = .disconnected
    reconnectionAttempt = 0
    pingTask?.cancel()
    receiveTask?.cancel()
    
    webSocketTask?.cancel(with: .normalClosure, reason: nil)
    webSocketTask = nil
    
    // Cancel all pending requests
    let cancelError = NSError(domain: "DZWebSocketClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "WebSocket disconnected"])
    for (_, continuation) in pendingRequests {
      continuation.resume(throwing: cancelError)
    }
    pendingRequests.removeAll()
    
    for continuation in connectionContinuations {
      continuation.resume()
    }
    connectionContinuations.removeAll()
  }
  
  /// Waits asynchronously until the WebSocket reaches a `.connected` state.
  ///
  /// If the client is disconnected, this triggers a connection attempt.
  private func waitForConnection() async {
    if state == .connected {
      return
    }
    
    if state == .disconnected {
      connect()
    }

    await withCheckedContinuation { continuation in
      connectionContinuations.append(continuation)
    }
  }
  
  /// Sends a payload to the WebSocket server and waits for a specific response.
  ///
  /// - Parameters:
  ///   - message: The payload to send, conforming to `WebSocketEvent`.
  ///   - responseType: The expected `Decodable` type of the response.
  /// - Throws: Any encoding/decoding errors, networking errors, or cancellation errors if the connection drops.
  public func send<T: WebSocketEvent, U: Decodable & Sendable>(message: T, responseType: U.Type) async throws -> U {
    await waitForConnection()
    
    let eventId = message.eventId
    let data = try encoder.encode(message)
    let wsMessage = URLSessionWebSocketTask.Message.data(data)
    
    let responseData: Data = try await withTaskCancellationHandler {
      return try await withCheckedThrowingContinuation { continuation in
        Task {
          self.addPendingRequest(eventId: eventId, continuation: continuation)
          
          do {
            try await self.webSocketTask?.send(wsMessage)
          }
          catch {
            self.failPendingRequest(eventId: eventId, error: error)
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
  /// - Throws: Any encoding errors or networking errors if the dispatch fails.
  public func send<T: WebSocketEvent>(message: T) async throws {
    await waitForConnection()
    
    let data = try encoder.encode(message)
    let wsMessage = URLSessionWebSocketTask.Message.data(data)
    try await webSocketTask?.send(wsMessage)
  }
  
  /// Sends raw data over the WebSocket.
  public func send(data: Data) async throws {
    await waitForConnection()
    let wsMessage = URLSessionWebSocketTask.Message.data(data)
    try await webSocketTask?.send(wsMessage)
  }
  
  /// Sends a raw string over the WebSocket.
  public func send(string: String) async throws {
    await waitForConnection()
    let wsMessage = URLSessionWebSocketTask.Message.string(string)
    try await webSocketTask?.send(wsMessage)
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
  /// The stream automatically cleans up its internal handler when the iterating `Task` is cancelled.
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
    receiveTask = Task {
      while !Task.isCancelled {
        guard let task = self.webSocketTask else { break }
        
        do {
          let message = try await task.receive()
          self.handleIncomingMessage(message)
        }
        catch {
          // The delegate's handleDidClose / handleDidComplete will trigger the reconnection.
          break
        }
      }
    }
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
  
  private func handleDisconnection() {
    // Only transition if we are truly losing connection unexpectedly
    guard state == .connected || state == .connecting else {
      return
    }

    state = .reconnecting
    webSocketTask?.cancel()
    
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
    
    Task {
      try? await Task.sleep(for: .seconds(delay))
      if self.state == .reconnecting {
        self.connect()
      }
    }
  }
  
  private func startPinging() {
    pingTask?.cancel()
    pingTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(10))
        if Task.isCancelled { break }
        
        self.sendPing()
      }
    }
  }
  
  private func sendPing() {
    webSocketTask?.sendPing { [weak self] error in
      if let error = error {
        print("DZWebSocketClient: Ping failed: \(error)")
        // Force disconnect so reconnect loop handles it
        Task { [weak self] in
          await self?.handleDisconnection()
        }
      }
    }
  }
  
  // MARK: - Dictionary Helpers
  
  private func addPendingRequest(eventId: String, continuation: CheckedContinuation<Data, Error>) {
    pendingRequests[eventId] = continuation
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
  var eventId: String { get }
}

// MARK: - WebSocketDelegate
private final class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate, Sendable {
  let onOpen: @Sendable () -> Void
  let onClose: @Sendable (URLSessionWebSocketTask.CloseCode, Data?) -> Void
  let onComplete: @Sendable (Error?, HTTPURLResponse?) -> Void

  init(onOpen: @escaping @Sendable () -> Void,
       onClose: @escaping @Sendable (URLSessionWebSocketTask.CloseCode, Data?) -> Void,
       onComplete: @escaping @Sendable (Error?, HTTPURLResponse?) -> Void) {
    self.onOpen = onOpen
    self.onClose = onClose
    self.onComplete = onComplete
  }

  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    onOpen()
  }

  func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    onClose(closeCode, reason)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    onComplete(error, task.response as? HTTPURLResponse)
  }
}
