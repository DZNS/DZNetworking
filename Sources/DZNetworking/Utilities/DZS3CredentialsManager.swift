//
//  DZS3CredentialsManager.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import Foundation
import Crypto

public enum DZS3Error: LocalizedError {
  case incompleteParamters
}

public enum DZACL: String {
  case `private`
  case `public`
}

public enum DZS3Encryption: String {
  case AES256
}

/// Credentials manager for S3 operations
///
/// Example:
/// ```swift
/// let credentials = DZS3CredentialsManager(key: "foo", secret: "bar")
/// let (authHeaderValue, expiresString) = try credentails.authorization(
///  with: .PUT,
///  bucket: "mybucket",
///  path: "/2049/12/24/secrets.txt",
///  contentType: "text/plain"
/// )
/// ```
public struct DZS3CredentialsManager {
  /// the `AWSAccessKey`
  public let key: String
  /// the `AWSAccessSecret`
  public let secret: String
  
  /// signing key derived from the secret
  fileprivate let signingKey: SymmetricKey
  
  /// date formatter for deriving string value of the expiry segment 
  fileprivate let dateFormatter: DateFormatter = {
    var df = DateFormatter()
    df.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
    df.locale = Locale(identifier: "en_US_POSIX")
    df.timeZone = TimeZone(secondsFromGMT: 0)
    return df
  }()
  
  public init(key: String, secret: String) {
    self.key = key
    self.secret = secret
    self.signingKey = SymmetricKey(data: secret.data(using: .utf8)!)
  }
  
  /// Generate the authorization token to be used for an S3 (or compatible service) request
  /// - Parameters:
  ///   - method: the HTTP Method
  ///   - bucket: the bucket name
  ///   - path: the path for the object
  ///   - acl: the acesss control list option
  ///   - encryption: s3 on-disk encryption type (optional)
  ///   - contentType: the content type of the data, if uploading an object (PUT, POST, PATCH)
  ///   - expires: the expiry interval of the request from `now`
  /// - Returns: `Authentication` header value
  public func authorization(with method: HTTPMethod, bucket: String, path: String, acl: DZACL? = .private, encryption: DZS3Encryption? = .AES256, contentType: String?, expires: TimeInterval = 3600) throws -> (String, String) {
    if method == .PUT || method == .POST || method == .PATCH {
      guard let _ = acl,
            let _ = encryption,
            let _ = contentType else {
        throw DZS3Error.incompleteParamters
      }
    }
    
    let expiryDate = Date().addingTimeInterval(expires)
    let expiresString = dateFormatter.string(from: expiryDate)
    
    var stringToSign = "\(method.rawValue)\n"
    // content-md5 goes in here, but AWS doesn't seem to care and throws an error.
    stringToSign = stringToSign.appendingFormat("%@\n", "")
    stringToSign.append("\n")
    stringToSign = stringToSign.appendingFormat("%@\n", expiresString)
    
    if let acl {
      stringToSign = stringToSign.appendingFormat("x-amz-acl:%@\n", acl.rawValue)
    }
    
    if let encryption {
      stringToSign = stringToSign.appendingFormat("x-amz-server-side-encryption:%@\n", encryption.rawValue)
    }
    
    stringToSign = stringToSign.appendingFormat("/%@%@", bucket, path)
    
    #if DEBUG
    print("DZS3CredentialsManager: string to sign: \(stringToSign)")
    #endif
    
    let signedString = HMAC<SHA256>.authenticationCode(for: stringToSign.data(using: .utf8)!, using: signingKey)
    let signature = Data(signedString).base64EncodedString()
    let headerValue = String(format: "AWS %@:%@", key, signature)
    
    return (headerValue, expiresString)
  }
}
