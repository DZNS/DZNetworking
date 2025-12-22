//
//  NSError+DZError.swift
//  DZNetworking
//
//  Created by Nikhil Nigade on 22/12/25.
//

import Foundation

public extension NSError {
  /// If the error contains `DZError` information from `DZNetworking`, extracts that information and provides a new NSError (with localized error information if available)
  func networkErrorOrError() -> NSError {
    if let errorData = userInfo[DZErrorData] as? Data {
      if let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any] {
        if let message = json["reason"] as? String {
          return NSError(domain: self.domain, code: self.code, userInfo: [
            NSLocalizedDescriptionKey: message
          ])
        }
      }
      
      let message = String(data: errorData, encoding: .utf8)
      return NSError(domain: self.domain, code: self.code, userInfo: [
        NSLocalizedDescriptionKey: message ?? self.localizedDescription
      ])
    }
    
    return self
  }
}

/// If the error contains `DZError` information from `DZNetworking`, extracts that information and provides a new NSError (with localized error information if available)
public extension Error {
  func networkErrorOrError() -> NSError {
    (self as NSError).networkErrorOrError()
  }
}
