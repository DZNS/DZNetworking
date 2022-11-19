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
    ua = String(format: "%@/%@ (%@; tvOS %@; Scale/%0.2f)", name ?? "No Name", version ?? "0.1", device, systemVersion, scale)
    #elseif os(watchOS)
    ua = String(format: "%@/%@ (%@; watchOS %@; Scale/%0.2f)", name ?? "No Name", version ?? "0.1", device, systemVersion, scale)
    #else
    ua = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", name ?? "No Name", version ?? "0.1", device, systemVersion, scale)
    #endif
    #else
    ua = String(format: "%@/%@ (%@; iOS %@; Scale/%0.2f)", name ?? "No Name", version ?? "0.1", device, systemVersion, scale)
    #endif
    
    return ua
  }()
  
  static func GET(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    var urlString = url
    if let queryString = FormURLEncode(query ?? [:]) {
      urlString = urlString.appendingFormat("?%@", queryString)
    }
    
    guard let url = URL(string: urlString) else {
      throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: [NSLocalizedDescriptionKey: "The provided URL was invalid"])
    }
    
    let request = mutableRequest()
    request.httpMethod = "GET"
    request.url = url
    return request
  }
  
  static func POST(_ url: String, query: [String: String]? = [:], body: [String: AnyHashable]? = [:]) throws -> NSMutableURLRequest {
    var urlString = url
    if let queryString = FormURLEncode(query ?? [:]) {
      urlString = urlString.appendingFormat("?%@", queryString)
    }
    
    guard let url = URL(string: urlString) else {
      throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: [NSLocalizedDescriptionKey: "The provided URL was invalid"])
    }
    
    let contentType = String(format: "multipart/form-data; charset=%@; boundary=%@", "", "")
    
    let request = mutableRequest()
    request.httpMethod = "POST"
    request.url = url
    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
    return request
  }
  
  static func POST(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func PUT(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func PUT(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func PATCH(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func DELETE(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func OPTIONS(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
  
  static func HEAD(_ url: String, query: [String: String]? = [:]) throws -> NSMutableURLRequest {
    
  }
}

// MARK: - Private
private extension HTTPURLRQ {
  static func mutableRequest() -> NSMutableURLRequest {
    var request = NSMutableURLRequest()
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    return request
  }
}
