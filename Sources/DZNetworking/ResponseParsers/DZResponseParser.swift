//
//  DZResponseParser.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

/// Base protocol for parsing `Data` responses into any arbitrary format, class, struct as desired.
///
/// The framework implements a `DZJSONResponseParser` which parses `Data` into JSON `[String: AnyHashable]` collections.
///
/// It it not necessary to use one with an instance of `DZURLSession` if you directly plan to consume the `Data` responses or use the various methods that return `Codable` objects.
public protocol DZResponseParser {
  
  /// A set of acceptable content-types supported by the response parser.
  ///
  /// This is checked before parsing the information. If the content-type does not match, you can possibly return back the `Data` itself, or perhaps, try parsing it and handle any exceptions on the way.
  ///
  /// Refer to https://datatracker.ietf.org/doc/html/rfc6838 for more information on mime types used in API layers
  var contentTypes: Set<String> { get }
  
  func isExpectedContentType(in response: HTTPURLResponse) -> Bool
  
  func parseResponse(data: Data, response: HTTPURLResponse) throws -> Decodable?
}

extension DZResponseParser {
  func isExpectedContentType(in response: HTTPURLResponse) -> Bool {
    var contentType = response.value(forHTTPHeaderField: "Content-Type") ?? "(null)"
    
    if contentType.contains(";") {
      contentType = String(contentType.split(separator: ";").first!)
    }
    
    return contentTypes.contains(contentType)
  }
}
