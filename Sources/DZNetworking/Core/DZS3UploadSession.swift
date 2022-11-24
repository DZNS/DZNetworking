//
//  DZS3UploadSession.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import Foundation

public final class DZS3UploadSession: NSObject {
  
  public let credentials: DZS3CredentialsManager
  
  public init(credentials: DZS3CredentialsManager) {
    self.credentials = credentials
    super.init()
  }
  
  private let session = DZURLSession()
  
  public func upload(file: URL, bucket: String, path: String, acl: DZACL = .private, encryption: DZS3Encryption = .AES256, expires: TimeInterval = 3600, contentType: String = "application/octet-stream") async throws  -> (Any?, HTTPURLResponse) {
    
    guard file.startAccessingSecurityScopedResource(),
          let data = try? Data(contentsOf: file) else{
      throw PublicError.fileReadNoPermission
    }
    
    file.stopAccessingSecurityScopedResource()
    
    let (authorizationHeader, expiresString) = try credentials.authorization(
      with: .PUT,
      bucket: bucket,
      path: path,
      acl: acl,
      encryption: encryption,
      contentType: contentType,
      expires: expires
    )
    
    guard let url = URL(string: "/\(bucket)\(path)", relativeTo: URL(string: "https://s3.amazonaws.com")!) else {
      throw PublicError.invalidURL
    }
    
    let request = NSMutableURLRequest(url: url)
    request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
    request.setValue(acl.rawValue, forHTTPHeaderField: "X-Amz-Acl")
    request.setValue(encryption.rawValue, forHTTPHeaderField: "X-amz-server-size-encryption")
    request.setValue("s3.amazonaws.com", forHTTPHeaderField: "Host")
    request.setValue(expiresString, forHTTPHeaderField: "Date")
    request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
    request.httpBody = data
    request.httpMethod = HTTPMethod.PUT.rawValue
    
    let (result, response) = try await session.session.upload(for: request as URLRequest, from: data)
    
    return (result, response as! HTTPURLResponse)
  }
}
