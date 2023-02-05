//
//  DZURLSession+Codable.swift
//  
//
//  Created by Nikhil Nigade on 21/11/22.
//

import Foundation

// MARK: - Codable

/// To use methods outlined below, no `responseParser` should be setup on the receiver.
///
/// These methods directly interface with the resulting `Data` object to decode into Codable wrappers
extension DZURLSession {
  static let decoder = JSONDecoder()
  
  /// Perform a `GET` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  /// - Returns: object and response if the request was successful
  public func GET<T>(_ uri: String, type: T.Type, query: [String: String] = [:], decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "GET", query: query, body: nil)
    guard let data = data as? Data else {
      throw PublicError.expectedData
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `POST` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  ///   - decoder: optional: A custom JSON Decoder instance
  /// - Returns: object and response if the request was successful
  public func POST<T>(_ uri: String, type: T.Type, query: [String: String] = [:], json: Any?, decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "POST", query: query, body: json)
    guard let data = data as? Data else {
      throw PublicError.expectedData
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `PUT` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  ///   - decoder: optional: A custom JSON Decoder instance
  /// - Returns: object and response if the request was successful
  public func PUT<T>(_ uri: String, type: T.Type, query: [String: String] = [:], json: Any?, decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "PUT", query: query, body: json)
    guard let data = data as? Data else {
      throw PublicError.expectedData
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `PATCH` request using a json object for the body
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - json: the json object for the request body
  ///   - decoder: optional: A custom JSON Decoder instance
  /// - Returns: object and response if the request was successful
  public func PATCH<T>(_ uri: String, type: T.Type, query: [String: String] = [:], json: Any?, decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "PATCH", query: query, body: json)
    guard let data = data as? Data else {
      throw PublicError.expectedData
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `DELETE` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - body: the json object for the request body
  ///   - decoder: optional: A custom JSON Decoder instance
  /// - Returns: object and response if the request was successful
  public func DELETE<T>(_ uri: String, type: T.Type, query: [String: String] = [:], body: Any?, decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "DELETE", query: query, body: body)
    guard let data = data as? Data,
          data.count > 3 else {
      // DELETE methods are not required to return a body in the response
      // if its missing, skip throwing an error
      return (nil, response)
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `OPTIONS` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - decoder: optional: A custom JSON Decoder instance
  /// - Returns: object (if available) and response if the request was successful
  public func OPTIONS<T>(_ uri: String, type: T.Type, query: [String: String] = [:], decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "OPTIONS", query: query, body: nil)
    guard let data = data as? Data,
          data.count > 3 else {
      // OPTIONS methods are not required to return a body in the response
      // if its missing, skip throwing an error
      return (nil, response)
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try? decoder.decode(T.self, from: data)
    return (object, response)
  }
  
  /// Perform a `HEAD` request
  /// - Parameters:
  ///   - uri: the uri (can be relative to the base URL if one is set)
  ///   - query: query parameters
  ///   - decoder: optional: A custom JSON Decoder instance 
  /// - Returns: object (if available) and response if the request was successful
  public func HEAD<T>(_ uri: String, type: T.Type, query: [String: String] = [:], decoder: JSONDecoder? = nil) async throws -> (T?, HTTPURLResponse) where T: Decodable {
    precondition(responseParser == nil, "Using a responseParser + codable methods is not supported")
    
    let (data, response) = try await request(with: uri, method: "HEAD", query: query, body: nil)
    guard let data = data as? Data,
          data.count > 3 else {
      // HEAD methods are not required to return a body in the response
      // if its missing, skip throwing an error
      return (nil, response)
    }
    
    let decoder = decoder ?? DZURLSession.decoder
    let object = try? decoder.decode(T.self, from: data)
    return (object, response)
  }
}
