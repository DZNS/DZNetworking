//
//  DZURLSession+Requests.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

// MARK: - Requests
extension DZURLSession {
  public func request(with uri: String, method: String, query: [String: String]? = nil, body: [String: AnyHashable]? = nil) async throws -> (Decodable, HTTPURLResponse) {
    
    let (data, response) = try await performRequest(with: uri, method: method, query: query ?? [:], body: body ?? [:])
    
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
    
    guard let responseParser = self.responseParser,
          responseParser.isExpectedContentType(in: response) else {
      
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
    
    let responseObject = try responseParser.parseResponse(data: data, response: response)
    
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
  public func performRequest(with uri: String, method: String, query: [String: String] = [:], body: [String: AnyHashable] = [:]) async throws -> (Data, HTTPURLResponse) {
    
    guard var url = URL(string: uri) else {
      throw PublicError.invalidURL
    }
    
    if !query.isEmpty,
       var components = URLComponents(string: uri) {
      components.queryItems = []
      
      for (key, value) in query {
        components.queryItems?.append(.init(name: key, value: value))
      }
      
      url = components.url ?? url
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
  private func urlRequest(with uri: String, method: String, body: [String: AnyHashable] = [:]) throws -> URLRequest {
    
    guard let url = URL(string: uri, relativeTo: baseURL) else {
      throw PublicError.invalidURL
    }
    
    var mutableRequest: NSMutableURLRequest = .init(url: url)
    mutableRequest.httpMethod = method.lowercased()
    
    if method.lowercased() == "put" || method.lowercased() == "post" {
      
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
