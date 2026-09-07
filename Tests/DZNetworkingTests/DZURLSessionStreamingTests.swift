//
//  DZURLSessionStreamingTests.swift
//
//
//  Created by Nikhil Nigade on 07/09/26.
//

import XCTest
@testable import DZNetworking

/// Serves a scripted response in chunks, so streaming can be tested without a server.
final class StreamingStubURLProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var statusCode = 200
  nonisolated(unsafe) static var chunks: [String] = []
  nonisolated(unsafe) static var lastRequest: URLRequest?

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    Self.lastRequest = request
    let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/event-stream"])!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    for chunk in Self.chunks {
      client?.urlProtocol(self, didLoad: Data(chunk.utf8))
    }
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

final class DZURLSessionStreamingTests: XCTestCase {
  private func makeSession() -> DZURLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StreamingStubURLProtocol.self]
    let session = DZURLSession(configuration: configuration, isBackgroundSession: false)
    session.baseURL = URL(string: "https://example.test")
    return session
  }

  override func setUp() {
    StreamingStubURLProtocol.statusCode = 200
    StreamingStubURLProtocol.chunks = []
    StreamingStubURLProtocol.lastRequest = nil
  }

  func testStreamYieldsLinesAsTheyArrive() async throws {
    StreamingStubURLProtocol.chunks = ["first\nsec", "ond\nthird\n"]
    let session = makeSession()

    let streamed = try await session.stream("/v1/stream", json: ["prompt": "hi"])
    var lines: [String] = []
    for try await line in streamed.lines {
      lines.append(line)
    }

    XCTAssertEqual(streamed.response.statusCode, 200)
    XCTAssertEqual(lines, ["first", "second", "third"])
    XCTAssertEqual(StreamingStubURLProtocol.lastRequest?.httpMethod, "POST")
  }

  func testStreamThrowsWithTheBodyOnAnErrorStatus() async throws {
    StreamingStubURLProtocol.statusCode = 429
    StreamingStubURLProtocol.chunks = [#"{"error":{"type":"rate_limit_error","message":"slow down"}}"#]
    let session = makeSession()

    do {
      _ = try await session.stream("/v1/stream", json: [:])
      XCTFail("expected an error")
    }
    catch let error as NSError {
      XCTAssertEqual(error.domain, DZErrorDomain)
      XCTAssertEqual(error.code, 429)
      let body = error.userInfo[DZErrorData] as? Data
      XCTAssertEqual(String(decoding: body ?? Data(), as: UTF8.self), StreamingStubURLProtocol.chunks[0])
    }
  }

  func testServerSentEventsParseEventsAcrossChunks() async throws {
    StreamingStubURLProtocol.chunks = [
      "event: message_start\ndata: {\"a\":1}\n\n",
      ": keep-alive\n",
      "event: content_block_delta\ndata: line one\ndata: line two\nid: 7\n\n",
      "data: trailing without blank line",
    ]
    let session = makeSession()

    let (events, response) = try await session.serverSentEvents("/v1/messages", json: ["stream": true])
    var received: [DZServerSentEvent] = []
    for try await event in events {
      received.append(event)
    }

    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(received, [
      DZServerSentEvent(event: "message_start", data: "{\"a\":1}"),
      DZServerSentEvent(event: "content_block_delta", data: "line one\nline two", id: "7"),
      DZServerSentEvent(event: nil, data: "trailing without blank line"),
    ])
    XCTAssertEqual(StreamingStubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Accept"), "text/event-stream")
  }

  func testParserDropsCommentsAndEmptyEvents() {
    var parser = DZServerSentEventParser()
    XCTAssertNil(parser.feed(line: ": comment"))
    XCTAssertNil(parser.feed(line: ""))
    XCTAssertNil(parser.feed(line: "data:no space"))
    XCTAssertEqual(parser.feed(line: ""), DZServerSentEvent(data: "no space"))
    XCTAssertNil(parser.flush())
  }

  func testStreamAppliesRequestModifierAndHeaders() async throws {
    StreamingStubURLProtocol.chunks = ["ok\n"]
    let session = makeSession()
    session.requestModifier = { request in
      request.setValue("modified", forHTTPHeaderField: "X-Modifier")
      return request
    }

    let streamed = try await session.stream("/v1/stream", headers: [("X-Extra", "yes")], json: [:])
    for try await _ in streamed.lines {}

    XCTAssertEqual(StreamingStubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Modifier"), "modified")
    XCTAssertEqual(StreamingStubURLProtocol.lastRequest?.value(forHTTPHeaderField: "X-Extra"), "yes")
  }
}
