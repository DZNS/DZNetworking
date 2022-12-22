//
//  DZJSONResponseParser.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

/// A JSON response parser.
///
/// Supports the following content types:
///  - `application/json`
///  - `text/javascript`
///  - `text/json`
///
///  JSON5 structures decoding available on supported platforms.
final class DZJSONResponseParser: DZResponseParser {
  let contentTypes = Set<String>(["application/json", "text/javascript", "text/json"])
  
  func parseResponse(data: Data, response: HTTPURLResponse) throws -> Any? {
    var options: JSONSerialization.ReadingOptions = .fragmentsAllowed
    
    if #available(iOS 15, macOS 12, watchOS 8, tvOS 12, *) {
      options.insert(.json5Allowed)
    }
    
    let jsonObject = try JSONSerialization.jsonObject(with: data, options: options)
    
    return jsonObject
  }
}
