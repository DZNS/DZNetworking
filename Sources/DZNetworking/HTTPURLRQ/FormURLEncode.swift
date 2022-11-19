//
//  FormURLEncode.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

// MARK: Public
/// Express this dictionary as a `application/x-www-form-urlencoded` string.
///
/// Most users would recognize the result of this transformation as the query string in a browser bar. For our purposes it is the query string in a GET request and the HTTP body for POST, PUT and DELETE requests.
/// - Parameters:
///   - parameters: the URL query items
/// - Returns: String to use as the search param in `URLComponents`, if the parameters dictionary is nil or empty, returns `nil`
public func FormURLEncode(_ parameters: [String: String]) -> String? {
  guard !parameters.isEmpty else {
    return nil
  }
  
  var queryString = ""
  var parts = queryMagic(nil, parameters).makeIterator()
  
  while true {
    guard let key = parts.next(),
          let value = parts.next() else {
      break
    }
    
    queryString = queryString.appendingFormat("%@=%@&", encodeKey(key), encodeValue(value))
  }
  
  queryString = String(queryString.suffix(1))
  
  return queryString
}

// MARK: Private
private func sortAscending(_ lhs: CustomStringConvertible, _ rhs: CustomStringConvertible) -> Bool {
  lhs.description.compare(rhs.description) == .orderedAscending
}

private func queryMagic(_ key: String?, _ value: Any) -> Array<String> {
  var parts: [String] = []
  
  if let value = value as? [String: AnyHashable] {
    Array(value.keys).sorted(by: sortAscending).forEach { nestedKey in
      guard let nestedValue = value[nestedKey] else {
        return
      }
      
      let recursiveKey = key != nil ? "\(key!)[\(nestedKey)]" : nestedKey
      parts.append(contentsOf: queryMagic(recursiveKey, nestedValue))
    }
  }
  else if let value = value as? [AnyHashable] {
    value.forEach {
      parts.append(contentsOf: queryMagic("\(key ?? "")[]", $0))
    }
  }
  else if let value = value as? Set<AnyHashable> {
    value.sorted(by: sortAscending).forEach {
      parts.append(contentsOf: queryMagic(key, $0))
    }
  }
  else if let value = value as? String,
          let key {
    parts.append(contentsOf: [key, value])
  }
  
  return parts
}

private func encodeKey(_ text: String) -> String {
  encode(text, ignore: "[]")
}

private func encodeValue(_ text: String) -> String {
  encode(text, ignore: "")
}

private func encode(_ text: String, ignore: String) -> String {
  var allowedSet: CharacterSet = .init(charactersIn: ignore)
  allowedSet.formUnion(.urlQueryAllowed)
  allowedSet.remove(charactersIn: #":/?&=;+!@#$()',*"#)
  
  return text.addingPercentEncoding(withAllowedCharacters: allowedSet) ?? text
}
