//
//  DZUploadSession.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import Foundation

public final class DZUploadSession: NSObject {
  static public let shared = DZUploadSession()
  
  public let session = DZURLSession()
  
  public func upload(file: URL, fieldName: String, uri: String, query: [String: String]?, parameters: [String: String]? = nil, contentType: String = "application/octet-stream") async throws -> (Any?, HTTPURLResponse) {
    
    let multiPartData = MultipartFormData()
    
    guard file.startAccessingSecurityScopedResource() else {
      throw PublicError.fileReadNoPermission
    }
    
    let fileData = try Data(contentsOf: file)
    
    file.stopAccessingSecurityScopedResource()
    
    var fileName = file.lastPathComponent
    if fileName.isEmpty {
      fileName = "file.data"
    }
    
    multiPartData.add(file: fileData, name: fieldName, filename: fileName, contentType: contentType)
    
    if let parameters {
      multiPartData.add(parameters: parameters)
    }
    
    let bodyData = multiPartData.body
    
    let (result, response) = try await session.request(with: uri, method: HTTPMethod.POST.rawValue, query: query, body: bodyData)
    
    return (result, response)
  }
  
  public func upload(data: Data, fileName: String, fieldName: String, uri: String, query: [String: String]?, parameters: [String: String]? = nil, contentType: String = "application/octet-stream") async throws -> (Any?, HTTPURLResponse) {
    
    let multiPartData = MultipartFormData()
    
    multiPartData.add(file: data, name: fieldName, filename: fileName, contentType: contentType)
    
    if let parameters {
      multiPartData.add(parameters: parameters)
    }
    
    let bodyData = multiPartData.body
    
    let (result, response) = try await session.request(with: uri, method: HTTPMethod.POST.rawValue, query: query, body: bodyData)
    
    return (result, response)
  }
}
