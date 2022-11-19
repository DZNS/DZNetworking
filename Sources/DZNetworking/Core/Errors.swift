//
//  Errors.swift
//  
//
//  Created by Nikhil Nigade on 18/11/22.
//

import Foundation

public let DZErrorDomain = "DZErrorDomain"
public let DZErrorData = "DZErrorData"
public let DZErrorResponseObject = "DZErrorResponseObject"

public func dzError(code: Int, description: String, failure: String?) -> NSError {
  var userInfo: [String: String] = [NSLocalizedDescriptionKey: description]
  
  if let failure {
    userInfo[NSLocalizedFailureReasonErrorKey] = failure
  }
  
  return NSError(
    domain: DZErrorDomain,
    code: code,
    userInfo: userInfo
  )
}

public func dzObjectError(code: Int, description: String, data: Data, responseObject: Decodable?) -> NSError {
  var userInfo: [String: Any] = [
    NSLocalizedDescriptionKey: description,
    DZErrorData: data
  ]
  
  if let responseObject,
     (responseObject as? Data) != data {
    userInfo[DZErrorResponseObject] = responseObject
  }
  
  return NSError(
    domain: DZErrorDomain,
    code: code,
    userInfo: userInfo
  )
}

enum PublicError: LocalizedError {
  case invalidURL
  /// when URLResponse cannot be mapped to HTTPURLResponse 
  case invalidResponseType
}
