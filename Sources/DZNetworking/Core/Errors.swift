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
  /// the file to be uploaded could not be read due to read permission errors 
  case fileReadNoPermission
  
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return NSLocalizedString("An invalid URL was passed for this request.", comment: "")
    case .invalidResponseType:
      return NSLocalizedString("An invalid response type was received for this request.", comment: "")
    case .invalidBodyParameters:
      return NSLocalizedString("An invalid list of body parameters was passed for this request.", comment: "")
    case .invalidBodyParameter:
      return NSLocalizedString("An invalid body parameter was passed for this request.", comment: "")
    case .expectedData:
      return NSLocalizedString("The response body was empty.", comment: "")
    case .fileReadNoPermission:
      return NSLocalizedString("No permissions to read this file.", comment: "")
    }
  }
  
  var failureReason: String? {
    errorDescription
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .invalidURL:
      return NSLocalizedString("Check the URL and ensure it has been formatted properly.", comment: "")
    case .invalidResponseType:
      return NSLocalizedString("Check the response type. When using a custom response parser, ensure it can correctly handle this response type.", comment: "")
    case .invalidBodyParameters:
      return NSLocalizedString("Check body parameters passed for this request.", comment: "")
    case .invalidBodyParameter:
      return NSLocalizedString("Check the body parameter passed for this request.", comment: "")
    case .expectedData:
      return NSLocalizedString("This should only happen for OPTIONS and HEAD requests. Other request types should generally include a body.", comment: "")
    case .fileReadNoPermission:
      return NSLocalizedString("Ensure that the file URL is not security scoped by the OS.", comment: "")
    }
  }
}
