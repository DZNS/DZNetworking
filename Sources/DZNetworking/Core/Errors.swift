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

public func dzObjectError(code: Int, description: String, data: Data, responseObject: Any?) -> NSError {
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
  /// thrown when encoding parameters to data fails 
  case invalidBodyParameters
  /// the type of  the body parameter should either be `[String: AnyHashable]` or `MultipartFormData`
  case invalidBodyParameter
  /// expected `Data` as a response object, but got something else. If you have setup a `responseParser` on the session, you should unset it
  case expectedData
}
