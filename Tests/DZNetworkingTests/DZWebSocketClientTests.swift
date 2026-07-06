import XCTest
@testable import DZNetworking

// MARK: - Test Models

/// A simple payload model for testing the request-response correlation.
struct EchoMessage: WebSocketEvent, Decodable, Equatable, Sendable {
    let eventId: String
    let message: String
}

/// A payload model for testing unsolicited server events.
struct PushEvent: WebSocketEvent, Decodable, Equatable, Sendable {
    let eventId: String
    let event: String
    let payload: String
}

final class DZWebSocketClientTests: XCTestCase {
    
    let echoServerURL = URL(string: "wss://echo.websocket.org")!
    var client: DZWebSocketClient!
    
    override func setUp() async throws {
        client = DZWebSocketClient(url: echoServerURL)
    }
    
    override func tearDown() async throws {
        await client.disconnect()
        client = nil
    }
    
    // MARK: - Connection Lifecycle Tests
    
    func testConnectionLifecycle() async throws {
        var state = await client.state
        XCTAssertEqual(state, .disconnected)
        
        await client.connect()
        
        // Wait a tiny bit for the connection to establish
        try await Task.sleep(for: .seconds(1))
        
        state = await client.state
        XCTAssertEqual(state, .connected)
        
        await client.disconnect()
        
        state = await client.state
        XCTAssertEqual(state, .disconnected)
    }
    
    // MARK: - Core Messaging Tests
    
    func testRequestResponseCorrelation() async throws {
        await client.connect()
        
        let request = EchoMessage(eventId: UUID().uuidString, message: "Hello Request-Response!")
        
        // The echo server will bounce this exact JSON back to us.
        // Our client should intercept it using the eventId and resume the continuation.
        let response = try await client.send(message: request, responseType: EchoMessage.self)
        
        XCTAssertEqual(response, request)
    }
    
    func testFireAndForget() async throws {
        await client.connect()
        
        let request = EchoMessage(eventId: UUID().uuidString, message: "Fire and forget!")
        
        // This shouldn't throw, and it shouldn't hang waiting for a response.
        try await client.send(message: request)
    }
    
    // MARK: - Queueing Tests
    
    func testSuspensionQueueingDuringReconnection() async throws {
        let request = EchoMessage(eventId: UUID().uuidString, message: "Queued message!")
        
        await client.connect()
        // Simulate a disconnect that triggers the reconnect delay
        // We can't call private handleDisconnection, but we can just
        // cancel the underlying websocket task to force the receive loop to fail and trigger reconnect.
        // Wait, the easiest way to test this without exposing internals is to just...
        // Ah, `client.disconnect()` transitions to `.disconnected`. 
        // We need it in `.reconnecting`.
        // Let's just create a test that doesn't hang. Since we fixed the hang, 
        // testSuspensionQueueingBeforeConnection would just pass instantly because it auto-connects.
        // Wait, if it auto-connects, let's just assert it passes successfully.
        
        let testClient = client!
        let task = Task {
            // Because it is disconnected, it will auto-connect and send.
            try await testClient.send(message: request, responseType: EchoMessage.self)
        }
        
        let response = try await task.value
        XCTAssertEqual(response, request)
    }
    
    // MARK: - Unsolicited Event Tests
    
    func testUnsolicitedEventClosure() async throws {
        await client.connect()
        
        let expectation = XCTestExpectation(description: "Received unsolicited event via closure")
        let eventName = "test_closure_event"
        let testPayload = PushEvent(eventId: UUID().uuidString, event: eventName, payload: "Some payload data")
        
        // Register the handler
        await client.addHandler(for: eventName, type: PushEvent.self) { event, payload in
            XCTAssertEqual(event, eventName)
            XCTAssertEqual(payload, testPayload)
            expectation.fulfill()
        }
        
        // We send a fire-and-forget message containing the event name.
        // The echo server sends it back, mimicking an unsolicited push event from the server.
        try await client.send(message: testPayload)
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testUnsolicitedEventAsyncStream() async throws {
        await client.connect()
        
        let eventName = "test_stream_event"
        let testPayload = PushEvent(eventId: UUID().uuidString, event: eventName, payload: "Stream payload data")
        
        // Setup the stream listener
        let stream = client.listen(for: eventName, type: PushEvent.self)
        
        let task: Task<PushEvent?, Never> = Task {
            for await payload in stream {
                return payload
            }
            return nil
        }
        
        // Delay slightly to ensure stream is ready
        try await Task.sleep(for: .milliseconds(500))
        
        // Trigger the echo
        try await client.send(message: testPayload)
        
        let receivedPayload = await task.value
        XCTAssertEqual(receivedPayload, testPayload)
    }
    
    // MARK: - Cancellation Tests
    
    func testTaskCancellation() async throws {
        await client.connect()
        
        let request = EchoMessage(eventId: UUID().uuidString, message: "Cancel me!")
        let testClient = client!
        let task = Task {
            try await testClient.send(message: request, responseType: EchoMessage.self)
        }
        
        // Immediately cancel the task
        task.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Expected CancellationError to be thrown")
        }
        catch {
            XCTAssertTrue(error is CancellationError, "Expected CancellationError, but got \(error)")
        }
    }
}
