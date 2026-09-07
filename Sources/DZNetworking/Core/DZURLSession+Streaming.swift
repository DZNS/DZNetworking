//
//  DZURLSession+Streaming.swift
//
//
//  Created by Nikhil Nigade on 07/09/26.
//

import Foundation

/// A response whose body arrives over time: the HTTP head, then the body as lines.
///
/// Use it for server-sent events, newline-delimited JSON, or any long-lived response
/// where waiting for the whole body would defeat the purpose.
public struct DZStreamedResponse: Sendable {
  /// The response head. Available as soon as the server sends it, before any body.
  public let response: HTTPURLResponse
  /// The body, one line at a time, without line terminators. Finishes when the server
  /// closes the response, or throws when the connection fails mid-stream.
  public let lines: AsyncThrowingStream<String, any Error>
}

/// One event from a server-sent events stream, per the WHATWG EventSource spec.
public struct DZServerSentEvent: Sendable, Equatable {
  /// The `event:` field, when the server sent one.
  public let event: String?
  /// The `data:` field. Multiple `data:` lines join with a newline, as the spec requires.
  public let data: String
  /// The `id:` field, when the server sent one.
  public let id: String?

  public init(event: String? = nil, data: String, id: String? = nil) {
    self.event = event
    self.data = data
    self.id = id
  }
}

extension DZURLSession {
  /// Performs a request and returns the body as it streams in, line by line.
  ///
  /// The request goes through the same builder as every other request on the receiver:
  /// `baseURL`, the request modifiers, and the extra `headers` all apply. A status code
  /// above `maxSuccessStatusCode` reads the body (bounded) and throws the same error
  /// the non-streaming requests throw, with the body under `DZErrorData`.
  ///
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - method: the HTTP method; `POST` by default, since most streaming APIs take a body
  ///   - query: query parameters
  ///   - headers: additional headers, if any. `nil` value for the header field removes it.
  ///   - json: the json object for the request body, for methods that take one
  /// - Returns: the response head and the streaming body
  public func stream(_ uri: String, method: HTTPMethod = .POST, query: [String: String] = [:], headers: [(String, String?)] = [], json: Any? = nil) async throws -> DZStreamedResponse {
    guard let url = URL(string: uri, relativeTo: baseURL) else {
      throw PublicError.invalidURL
    }
    let request = try await urlRequest(with: url.absoluteString, method: method.rawValue, query: query, headers: headers, body: json)
    let (bytes, urlResponse) = try await session.bytes(for: request)
    guard let response = urlResponse as? HTTPURLResponse else {
      throw PublicError.invalidResponseType
    }

    if response.statusCode > maxSuccessStatusCode {
      let body = await Self.collect(bytes, limit: 256 * 1024)
      let responseObject = try? responseParser?.parseResponse(data: body, response: response)
      throw dzObjectError(code: response.statusCode, description: HTTPURLResponse.localizedString(forStatusCode: response.statusCode), data: body, responseObject: responseObject)
    }

    // Not `bytes.lines`: that sequence drops empty lines, and an empty line is what ends a
    // server-sent event. This splitter keeps them.
    let lines = AsyncThrowingStream<String, any Error> { continuation in
      let task = Task {
        var buffer = Data()
        do {
          for try await byte in bytes {
            try Task.checkCancellation()
            if byte == UInt8(ascii: "\n") {
              continuation.yield(Self.line(from: buffer))
              buffer.removeAll(keepingCapacity: true)
            }
            else {
              buffer.append(byte)
            }
          }
          if !buffer.isEmpty {
            continuation.yield(Self.line(from: buffer))
          }
          continuation.finish()
        }
        catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
    return DZStreamedResponse(response: response, lines: lines)
  }

  /// Performs a request against a server-sent events endpoint and returns parsed events.
  ///
  /// Same parameters and error behavior as ``stream(_:method:query:headers:json:)``. The
  /// `Accept: text/event-stream` header is set unless `headers` overrides it. Comment
  /// lines (starting with `:`) are dropped; an event is delivered at each blank line.
  public func serverSentEvents(_ uri: String, method: HTTPMethod = .POST, query: [String: String] = [:], headers: [(String, String?)] = [], json: Any? = nil) async throws -> (events: AsyncThrowingStream<DZServerSentEvent, any Error>, response: HTTPURLResponse) {
    var allHeaders = headers
    if !headers.contains(where: { $0.0.caseInsensitiveCompare("Accept") == .orderedSame }) {
      allHeaders.append(("Accept", "text/event-stream"))
    }
    let streamed = try await stream(uri, method: method, query: query, headers: allHeaders, json: json)
    let lines = streamed.lines
    let events = AsyncThrowingStream<DZServerSentEvent, any Error> { continuation in
      let task = Task {
        var parser = DZServerSentEventParser()
        do {
          for try await line in lines {
            if let event = parser.feed(line: line) {
              continuation.yield(event)
            }
          }
          if let last = parser.flush() {
            continuation.yield(last)
          }
          continuation.finish()
        }
        catch {
          continuation.finish(throwing: error)
        }
      }
      continuation.onTermination = { _ in
        task.cancel()
      }
    }
    return (events, streamed.response)
  }

  /// One line of body text, without a trailing carriage return.
  private static func line(from buffer: Data) -> String {
    var bytes = buffer
    if bytes.last == UInt8(ascii: "\r") {
      bytes.removeLast()
    }
    return String(decoding: bytes, as: UTF8.self)
  }

  /// Reads up to `limit` bytes of a body, for error responses that are worth inspecting.
  private static func collect(_ bytes: URLSession.AsyncBytes, limit: Int) async -> Data {
    var data = Data()
    do {
      for try await byte in bytes {
        data.append(byte)
        if data.count >= limit {
          break
        }
      }
    }
    catch {
      // A body that fails mid-read still yields what arrived.
    }
    return data
  }
}

/// Turns lines into server-sent events. Feed every line; an event is returned at each
/// blank line that closes a non-empty event, and `flush()` returns a trailing event that
/// the server never closed.
public struct DZServerSentEventParser: Sendable {
  private var event: String?
  private var dataLines: [String] = []
  private var id: String?

  public init() {}

  public mutating func feed(line: String) -> DZServerSentEvent? {
    if line.isEmpty {
      return flush()
    }
    if line.hasPrefix(":") {
      return nil
    }
    let (field, value) = Self.split(line)
    switch field {
    case "event":
      event = value
    case "data":
      dataLines.append(value)
    case "id":
      id = value
    default:
      break
    }
    return nil
  }

  public mutating func flush() -> DZServerSentEvent? {
    guard !dataLines.isEmpty || event != nil else {
      return nil
    }
    let built = DZServerSentEvent(event: event, data: dataLines.joined(separator: "\n"), id: id)
    event = nil
    dataLines = []
    id = nil
    return built
  }

  /// `field: value` per the spec: the first colon splits, one leading space is dropped.
  private static func split(_ line: String) -> (String, String) {
    guard let colon = line.firstIndex(of: ":") else {
      return (line, "")
    }
    let field = String(line[line.startIndex..<colon])
    var value = String(line[line.index(after: colon)...])
    if value.hasPrefix(" ") {
      value.removeFirst()
    }
    return (field, value)
  }
}
