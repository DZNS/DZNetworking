//
//  DZURLSession+Requests.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

public typealias SuccessCallback = (_ responseObject: Any, _ response: HTTPURLResponse) -> Void
public typealias ErrorCallback = (_ error: Error) -> Void

public enum HTTPMethod: String {
  case GET
  case POST
  case PUT
  case PATCH
  case DELETE
  case OPTIONS
  case HEAD
}

// MARK: - Convenience
extension DZURLSession {
  // MARK: Async

  /// Perform a `GET` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  /// - Returns: data and response if the request was successful
  public func GET(_ uri: String, query: [String: String] = [:]) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "GET", query: query, body: nil)
  }
  
  /// Perform a `POST` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  /// - Returns: data and response if the request was successful
  public func POST(_ uri: String, query: [String: String] = [:], json: Any?) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "POST", query: query, body: json)
  }
  
  /// Perform a `PUT` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  /// - Returns: data and response if the request was successful
  public func PUT(_ uri: String, query: [String: String] = [:], json: Any?) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "PUT", query: query, body: json)
  }
  
  /// Perform a `PATCH` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  /// - Returns: data and response if the request was successful
  public func PATCH(_ uri: String, query: [String: String] = [:], json: Any?) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "PATCH", query: query, body: json)
  }
  
  /// Perform a `DELETE` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - body: the json object for the request body
  /// - Returns: data and response if the request was successful
  public func DELETE(_ uri: String, query: [String: String] = [:], body: Any?) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "DELETE", query: query, body: body)
  }
  
  /// Perform a `OPTIONS` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  /// - Returns: data and response if the request was successful
  public func OPTIONS(_ uri: String, query: [String: String] = [:]) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "OPTIONS", query: query, body: nil)
  }
  
  /// Perform a `HEAD` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  /// - Returns: data and response if the request was successful
  public func HEAD(_ uri: String, query: [String: String] = [:]) async throws -> (Any, HTTPURLResponse) {
    try await request(with: uri, method: "HEAD", query: query, body: nil)
  }
  
  // MARK: Completion Handlers
  @discardableResult public func GET(_ uri: String, query: [String: String] = [:], onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "GET", query: query, body: nil)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func POST(_ uri: String, query: [String: String] = [:], json: Any?, onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "POST", query: query, body: json)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func PUT(_ uri: String, query: [String: String] = [:], json: Any?, onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "PUT", query: query, body: json)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func PATCH(_ uri: String, query: [String: String] = [:], json: Any?, onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "PATCH", query: query, body: json)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func DELETE(_ uri: String, query: [String: String] = [:], body: Any?, onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "DELETE", query: query, body: body)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func OPTIONS(_ uri: String, query: [String: String] = [:], onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "OPTIONS", query: query, body: nil)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
  
  @discardableResult public func HEAD(_ uri: String, query: [String: String] = [:], onSuccess: @escaping SuccessCallback, onError: ErrorCallback?) -> _Concurrency.Task<Void, Never> {
    Task {
      do {
        let (responseObject, response) = try await request(with: uri, method: "HEAD", query: query, body: nil)
        DispatchQueue.main.async { onSuccess(responseObject, response) }
      }
      catch {
        DispatchQueue.main.async { onError?(error) }
      }
    }
  }
}

// MARK: - Requests
extension DZURLSession {
  public func request(with uri: String, method: String, query: [String: String]? = nil, body: Any? = nil) async throws -> (Any, HTTPURLResponse) {
    
    let (data, response) = try await performRequest(with: uri, method: method, query: query ?? [:], body: body)
    
    guard response.statusCode != 304 else {
      return (data, response)
    }
    
    // data is empty, treat as a 304 response
    guard !data.isEmpty else {
      return (data, response)
    }
    
    guard let contentType = response.allHeaderFields["Content-Type"] as? String else {
      // dont know how to parse, return the data as-is
      return (data, response)
    }
    
    if let responseParser = self.responseParser,
       !responseParser.isExpectedContentType(in: response) {
      var responseText: String = ""
      
      if contentType.contains("text/html") {
        var encoding: String.Encoding = .utf8
        
        if contentType.contains("charset="),
           let charsetRange = contentType.range(of: "charset=") {
          let charSetIndex = NSRange(charsetRange, in: contentType).location + 8
          let encodingType = String(contentType.suffix(charSetIndex)).lowercased()
          
          if encodingType == "utf-16" || encodingType == "utf16" {
            encoding = .utf16
          }
          else if encodingType == "utf-32" || encodingType == "utf32" {
            encoding = .utf32
          }
          else if encodingType == "ascii" {
            encoding = .ascii
          }
        }
        
        responseText = String(data: data, encoding: encoding) ?? ""
      }
      
      throw dzError(
        code: 503,
        description: NSLocalizedString("The content was not of the expected type", comment: "The content in the response was not of the expected type so parsing failed"),
        failure: responseText
      )
    }
    
    let responseObject = try responseParser?.parseResponse(data: data, response: response)
    
    if response.statusCode > maxSuccessStatusCode {
      // treat as an error
      throw dzObjectError(
        code: response.statusCode,
        description: HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
        data: data,
        responseObject: responseObject
      )
    }
    
    if response.statusCode == 200,
       responseObject == nil {
      // the request was successful, but no response was returned
      // such requests are common, eg. `/ping` or `options`
      return (data, response)
    }
    
    return (responseObject ?? data, response)
  }
  
  /// performs the request using the internal `URLSession` for the provided parameters
  /// - Parameters:
  ///   - uri: the URI of the request (can be a path, `baseURL` will be attached to it)
  ///   - method: the method of the request
  ///   - query: the query items for the request
  ///   - body: optional body for PUT, POST, PATCH requests
  /// - Returns: `Data` and `HTTPURLResponse` tuple if successful, else throws an error
  public func performRequest(with uri: String, method: String, query: [String: String] = [:], body: Any? = nil) async throws -> (Data, HTTPURLResponse) {
    
    guard let url = URL(string: uri, relativeTo: baseURL) else {
      throw PublicError.invalidURL
    }
    
    let request = try urlRequest(with: url.absoluteString, method: method, body: body)
    
    let (data, response) = try await session.data(for: request)
    
    guard let response = response as? HTTPURLResponse else {
      throw PublicError.invalidResponseType
    }
    
    return (data, response)
  }
  
  // MARK: Internal  
  
  /// Forms a `URLRequest` with the provided parameters
  /// - Parameters:
  ///   - uri: the URI of the request (can be a path, `baseURL` will be attached to it)
  ///   - method: the method of the request
  ///   - body: optional body for PUT, POST, PATCH requests
  /// - Returns: `URLRequest` for using with a `URLSession`
  private func urlRequest(with uri: String, method: String, query: [String: String] = [:], body: Any? = nil) throws -> URLRequest {
    var mutableRequest: NSMutableURLRequest
    
    switch method {
    case "POST":
      let usableBody = body ?? [String: String]()
      mutableRequest = try HTTPURLRQ.POST(uri, query: query, json: usableBody)
    case "PUT":
      let usableBody = body ?? [String: String]()
      mutableRequest = try HTTPURLRQ.PUT(uri, query: query, json: usableBody)
    case "PATCH":
      let usableBody = body ?? [String: String]()
      mutableRequest = try HTTPURLRQ.PATCH(uri, query: query, json: usableBody)
    case "DELETE":
      mutableRequest = try HTTPURLRQ.DELETE(uri, query: query, body: body as? [String: AnyHashable])
    case "OPTIONS":
      mutableRequest = try HTTPURLRQ.OPTIONS(uri, query: query)
    case "HEAD":
      mutableRequest = try HTTPURLRQ.HEAD(uri, query: query)
    default:
      mutableRequest = try HTTPURLRQ.GET(uri, query: query)
    }
    
    if let requestModifier {
      mutableRequest = requestModifier(mutableRequest)
    }
    
    let request = mutableRequest.copy() as! URLRequest
    
    // @TODO: sanitise the request
    // 1. the url should not have `?` if there are no query parameters
    
    return request
  }
}
