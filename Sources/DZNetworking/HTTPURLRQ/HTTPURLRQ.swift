//
//  HTTPURLRQ.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

/// This is Swift port OMGHTTPURLRQ
struct HTTPURLRQ {
  static let userAgent: String = {
    var ua = ""
    let info = Bundle.main.infoDictionary
    let name = info?[kCFBundleNameKey as String] as? String ?? info?[kCFBundleIdentifierKey as String] as? String
    let version = info?[kCFBundleVersionKey as String] as? String
    
    #if canImport(UIKit)
    let scale = UIScreen.main.scale
    let device = UIDevice.current.model
    let systemVersion = UIDevice.current.systemVersion
    
    #if os(tvOS)
    ua = String(format: "%@/%@ (%@; tvOS %@; Scale/%0.2f)", name ?? "NoName", version ?? "0.1", device, systemVersion, scale)
    #elseif os(watchOS)
    ua = String(format: "%@/%@ (%@; watchOS %@; Scale/%0.2f)", name ?? "NoName", version ?? "0.1", device, systemVersion, scale)
    #else
    ua = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", name ?? "NoName", version ?? "0.1", device, systemVersion, scale)
    #endif
    #else
    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
    let device = Host.current().localizedName ?? "NoDeviceName"
    let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
    let systemVersionString = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
    ua = String(format: "%@/%@ (%@; macOS %@; Scale/%0.2f)", name ?? "NoName", version ?? "0.1", device, systemVersionString, scale)
    #endif
    
    return ua
  }()
  
  static func GET(_ uri: String, query: [String: String] = [:]) throws -> NSMutableURLRequest {
    let url = try validURLForRequest(from: uri, query: query)
    
    let request = mutableRequest()
    request.httpMethod = "GET"
    request.url = url
    return request
  }
  
  static func POST(_ uri: String, query: [String: String] = [:], body: AnyObject) throws -> NSMutableURLRequest {
    let url = try validURLForRequest(from: uri, query: query)
    
    guard let body = body as? MultipartFormData else {
      if let body = body as? [String: AnyHashable] {
        return try formURLEncodeRequest(url, method: "POST", parameters: body)
      }
      
      throw PublicError.invalidBodyParameter
    }
    
    let contentType = String(format: "multipart/form-data; charset=%@; boundary=%@", "utf-8", body.boundary)
    
    var data = body.body
    let lastLine = String(format: "%@--%@--%@", body.lineEnding, body.boundary, body.lineEnding)
    data.append(lastLine.data(using: .utf8)!)
    
    let request = mutableRequest()
    request.url = url
    request.httpMethod = "POST"
    request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    request.httpBody = data
    
    return request
  }
  
  static func POST(_ uri: String, query: [String: String] = [:], json: Any) throws -> NSMutableURLRequest {
    
    let url = try validURLForRequest(from: uri, query: query)
    
    var body: Data
    if let data = json as? Data {
      body = data
    }
    else {
      body = try JSONSerialization.data(withJSONObject: json)
    }
    
    let request = mutableRequest()
    request.url = url
    request.httpMethod = "POST"
    request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.addValue("json", forHTTPHeaderField: "Data-Type")
    request.httpBody = body
    
    return request
  }
  
  static func PUT(_ uri: String, query: [String: String] = [:], body: [String: AnyHashable]) throws -> NSMutableURLRequest {
    let url = try validURLForRequest(from: uri, query: query)
    
    return try formURLEncodeRequest(url, method: "PUT", parameters: body)
  }
  
  static func PUT(_ uri: String, query: [String: String] = [:], json: Any) throws -> NSMutableURLRequest {
    let request = try POST(uri, query: query, json: json)
    request.httpMethod = "PUT"
    return request
  }
  
  static func PATCH(_ uri: String, query: [String: String] = [:], json: Any) throws -> NSMutableURLRequest {
    let request = try POST(uri, query: query, json: json)
    request.httpMethod = "PATCH"
    return request
  }
  
  static func DELETE(_ uri: String, query: [String: String] = [:], body: [String: AnyHashable]?) throws -> NSMutableURLRequest {
    let url = try validURLForRequest(from: uri, query: query)
    return try formURLEncodeRequest(url, method: "DELETE", parameters: body ?? [:])
  }
  
  static func OPTIONS(_ uri: String, query: [String: String] = [:]) throws -> NSMutableURLRequest {
    let request = try GET(uri, query: query)
    request.httpMethod = "OPTIONS"
    return request
  }
  
  static func HEAD(_ uri: String, query: [String: String] = [:]) throws -> NSMutableURLRequest {
    let request = try GET(uri, query: query)
    request.httpMethod = "HEAD"
    return request
  }
  
  static func formURLEncodeRequest(_ url: URL, method: String, parameters: [String: AnyHashable]) throws -> NSMutableURLRequest {
    let request = mutableRequest()
    request.url = url
    request.httpMethod = method
    
    request.addValue("8bit", forHTTPHeaderField: "Content-Transfer-Encoding")
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    if parameters.isEmpty {
      request.addValue("0", forHTTPHeaderField: "Content-Length")
    }
    else {
      let queryString = FormURLEncode(parameters)
      guard let data = queryString?.data(using: .utf8) else {
        throw PublicError.invalidBodyParameters
      }
      
      request.addValue("\(data.count)", forHTTPHeaderField: "Content-Length")
      request.httpBody = data
    }
    
    return request
  }
  
}

// MARK: - Private
private extension HTTPURLRQ {
  static func mutableRequest() -> NSMutableURLRequest {
    let request = NSMutableURLRequest()
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    return request
  }
  
  static func validURLForRequest(from uri: String, query: [String: String] = [:]) throws -> URL {
    var urlString = uri
    if let queryString = FormURLEncode(query) {
      urlString = urlString.appendingFormat("?%@", queryString)
    }
    
    guard let url = URL(string: urlString) else {
      throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: [NSLocalizedDescriptionKey: "The provided URL was invalid"])
    }
    
    return url
  }
}
