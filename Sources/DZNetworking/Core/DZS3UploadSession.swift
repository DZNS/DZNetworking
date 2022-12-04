//
//  DZS3UploadSession.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import Foundation

/// Session object to use for upload files to S3
///
/// Example:
/// ```
/// let session = DZS3UploadSession(
///   credentials: .init(key: "foo", secret: "bar")
/// )
///
/// let (_, response) = try await session.upload(file: fileURL, bucket: bucket, path: bucketPath, contentType: "text/plain")
///
/// guard response.statusCode <= 204 else {
///    throw Error
/// }
/// ```
public final class DZS3UploadSession: NSObject {
  
  /// AWS credentials for the session
  ///
  /// Persisted throughout the lifetime of the session. If you need to use different credentials, it's recommended to create a new session.
  public let credentials: DZS3CredentialsManager
  
  public init(credentials: DZS3CredentialsManager) {
    self.credentials = credentials
    super.init()
  }
  
  private let session = DZURLSession()
  
  /// Uploads a file to S3
  /// - Parameters:
  ///   - file: the file to upload
  ///   - bucket: the bucket's name
  ///   - path: the bucket path (must start with a trailing slash)
  ///   - acl: the acl for the object, `private` by default
  ///   - encryption: on-disk encryption for the object (`none` by default)
  ///   - expires: the expiry time of the request, relative to now (default is 1 hour)
  ///   - contentType: the content type of the file
  /// - Returns: resultant object and http response
  public func upload(file: URL, bucket: String, path: String, acl: DZACL = .private, encryption: DZS3Encryption = .none, expires: TimeInterval = 3600, contentType: String = "application/octet-stream") async throws  -> (Any?, HTTPURLResponse) {
    
    guard file.startAccessingSecurityScopedResource(),
          let data = try? Data(contentsOf: file) else{
      throw PublicError.fileReadNoPermission
    }
    
    file.stopAccessingSecurityScopedResource()
    
    guard let url = URL(string: "/\(bucket)\(path)", relativeTo: URL(string: "https://s3.amazonaws.com")!) else {
      throw PublicError.invalidURL
    }
    
    let request = NSMutableURLRequest(url: url)
    request.httpBody = data
    request.httpMethod = HTTPMethod.PUT.rawValue
    
    guard let signedRequest = try credentials.authorize(request: request) else {
      throw DZS3Error.incompleteParamters
    }
    
    let (result, response) = try await session.session.upload(for: signedRequest as URLRequest, from: data)
    
    return (result, response as! HTTPURLResponse)
  }
}
