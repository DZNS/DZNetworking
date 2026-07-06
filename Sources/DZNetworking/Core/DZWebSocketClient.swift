import Foundation

/// A protocol that every outgoing WebSocket message must conform to.
///
/// By conforming to this protocol, the WebSocket client can extract the `eventId`
/// to correlate request and response payloads automatically.
public protocol WebSocketEvent: Encodable & Sendable {
  /// A unique identifier for the event. Used to match responses to requests.
  var eventId: String { get }
}

/// An actor that manages a persistent WebSocket connection, providing
/// request-response pairing, auto-reconnection, ping loops, and
/// routing for unsolicited events.
public actor DZWebSocketClient {
  /// Represents the current connection state of the WebSocket.
  public enum State: Sendable {
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
  private let urlSession: URLSession
  
  private var webSocketTask: URLSessionWebSocketTask?
  
  /// The current connection state of the client.
  public private(set) var state: State = .disconnected
  
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
  
  /// Initializes a new WebSocket client.
  ///
  /// - Parameters:
  ///   - url: The `URL` of the WebSocket server.
  ///   - urlSession: The `URLSession` to use for creating the underlying WebSocket task. Defaults to `.shared`.
  ///   - encoder: A `JSONEncoder` used to encode outgoing messages. Defaults to a standard `JSONEncoder`.
  ///   - decoder: A `JSONDecoder` used to decode incoming messages. Defaults to a standard `JSONDecoder`.
  public init(url: URL, urlSession: URLSession = .shared, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
    self.url = url
    self.urlSession = urlSession
    self.encoder = encoder
    self.decoder = decoder
  }
  
  /// Connects to the WebSocket server.
  ///
  /// If the client is already connected or in the process of connecting, this method does nothing.
  /// Calling this method transitions the state to `.connecting` and resumes pending operations once successful.
  public func connect() {
    guard state == .disconnected || state == .reconnecting else { return }
    
    let isReconnecting = state == .reconnecting
    state = isReconnecting ? .reconnecting : .connecting
    
    let request = URLRequest(url: url)
    webSocketTask = urlSession.webSocketTask(with: request)
    webSocketTask?.resume()
    
    state = .connected
    
    // Resume any pending connections
    for continuation in connectionContinuations {
      continuation.resume()
    }
    connectionContinuations.removeAll()
    
    startReceiving()
    startPinging()
  }
  
  /// Disconnects from the WebSocket server and cancels all pending tasks.
  ///
  /// Calling this method cancels any in-flight requests by throwing a cancellation error
  /// to their waiting continuations. The connection state transitions to `.disconnected`.
  public func disconnect() {
    state = .disconnected
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
      return
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
  /// - Returns: The decoded response of type `U`.
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
          if !Task.isCancelled {
            self.handleDisconnection()
          }
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
      guard let d = s.data(using: .utf8) else { return }
      data = d
    @unknown default:
      return
    }
    
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
      print("DZWebSocketClient: Failed to process incoming message: \(error)")
    }
  }
  
  private func handleDisconnection() {
    state = .reconnecting
    Task {
      try? await Task.sleep(for: .seconds(2))
      if self.state == .reconnecting {
        self.connect()
      }
    }
  }
  
  // MARK: - Ping Mechanism
  
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
    guard state == .connected, let task = webSocketTask else { return }
    task.sendPing { error in
      if let error = error {
        print("DZWebSocketClient: Ping failed: \(error)")
        Task {
          await self.handleDisconnection()
        }
      }
    }
  }
  
  // MARK: - Continuation Management
  
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
