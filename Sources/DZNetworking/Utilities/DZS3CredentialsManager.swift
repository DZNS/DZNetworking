//
//  DZS3CredentialsManager.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import Foundation
import CommonCrypto

public enum DZS3Error: LocalizedError {
  case incompleteParamters
}

/// The Access-Control-List used for the uploaded object. Can be `public` or `private`, defaults to `public`.
public enum DZACL: String {
  case `private`
  case `public`
}

/// The S3 at-rest encryption used for the uploaded object. `none` by default.
public enum DZS3Encryption: String {
  case `none`
  case AES256
}

/// Credentials manager for S3 operations
public struct DZS3CredentialsManager {
  /// the `AWSAccessKey`
  public let key: String
  /// the `AWSSecretKey`
  fileprivate let secretAccessKey: String
  /// the service (static)
  fileprivate let service = "s3"
  /// region to use (does not affect url of the request) 
  public let region: String
  
  /// AWS Style ISO8601 formatter
  private let iso8601Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd'T'HHmmssXXXXX"
    return formatter
  }()
  
  private let urlQueryAllowed: CharacterSet = .alphanumerics.union(.init(charactersIn: "-._~")) // as per RFC 3986
  
  public init(key: String, secret: String, region: String = "us-east-1") {
    self.key = key
    self.secretAccessKey = secret
    self.region = region
  }
  
  /// Signs the provided request for authenticating with AWS v4 API
  ///
  /// For uploads, the request must have valid:
  ///  - http method
  ///  - http body
  ///  - url
  /// - Parameter request: the request to authenticate
  /// - Returns: signed request
  public func authorize(request: NSMutableURLRequest) throws -> NSMutableURLRequest? {
    let signedRequest = request
    
    guard let url = signedRequest.url,
          let host = url.host else {
      return nil
    }
    
    let date = iso8601()
    let method = signedRequest.httpMethod
    
    signedRequest.addValue(host, forHTTPHeaderField: "Host")
    signedRequest.addValue(date.full, forHTTPHeaderField: "X-Amz-Date")
    
    var contentHash: String
    
    if method.lowercased() == "put" || method.lowercased() == "post" {
      contentHash = String(data: request.httpBody ?? Data(), encoding: .utf8)!.sha256()
      signedRequest.addValue(contentHash, forHTTPHeaderField: "x-amz-content-sha256")
    }
    else {
      contentHash = "".sha256()
      signedRequest.addValue("".sha256(), forHTTPHeaderField: "x-amz-content-sha256")
    }
    
    guard let headers = signedRequest.allHTTPHeaderFields else {
      return nil
    }
            
    let signedHeaders = headers.map { $0.key.lowercased() }.sorted().joined(separator: ";")
    
    let canonicalRequest = "\(method)\n\(url.path)\n\(url.query ?? "")\nhost:\(host)\nx-amz-content-sha256:\(contentHash)\nx-amz-date:\(date.full)\n\n\(signedHeaders)\n\(contentHash)"
    
    let canonicalRequestHash = canonicalRequest.sha256()
    
    let credential = getCredential(date: date.short, accessKeyId: key)
    
    let stringToSign = ["AWS4-HMAC-SHA256", date.full, credential, canonicalRequestHash].joined(separator: "\n")
    
    guard let signature = signatureWith(stringToSign: stringToSign, shortDateString: date.short) else {
      return nil
    }
    
    let authorization = "AWS4-HMAC-SHA256 Credential=" + key + "/" + credential + ",SignedHeaders=" + signedHeaders + ",Signature=" + signature
    signedRequest.addValue(authorization, forHTTPHeaderField: "Authorization")
    
    return signedRequest
  }
  
  /// returns a **credentials** string for including in the string to sign portion of the process
  ///
  /// composed of 4 components
  ///  - the short date (YYYYMMDD)
  ///  - the region
  ///  - the service (s3)
  ///  - static `aws4_request` string
  private func getCredential(date: String, accessKeyId: String) -> String {
    let credential = [date, region, service, "aws4_request"].joined(separator: "/")
    return credential
  }
  
  /// Generate the actual signature to be used in the auth header
  ///
  /// This uses the 4 step process to derive the signing key
  /// - Parameters:
  ///   - stringToSign: the string to sign formed using various components
  ///   - secretAccessKey: the secret key
  ///   - shortDateString: the shrot date string representation (YYYYMMDD)
  /// - Returns: signature for the header (hex encoded)
  private func signatureWith(stringToSign: String, shortDateString: String) -> String? {
    let firstKey = "AWS4" + secretAccessKey
    let dateKey = shortDateString.hmac(keyString: firstKey)
    let dateRegionKey = region.hmac(keyData: dateKey)
    let dateRegionServiceKey = service.hmac(keyData: dateRegionKey)
    let signingKey = "aws4_request".hmac(keyData: dateRegionServiceKey)
    let signature = stringToSign.hmac(keyData: signingKey)
    
    return signature.toHexString()
  }
  /// date representations, full and short (YYYYMMDD)
  private func iso8601() -> (full: String, short: String) {
    let date = iso8601Formatter.string(from: Date())
    let index = date.index(date.startIndex, offsetBy: 8)
    let shortDate = String(date[..<index])
    return (full: date, short: shortDate)
  }
}

private extension String {
  
  func sha256() -> String {
    guard let data = self.data(using: .utf8) else { return "" }
    var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
      _ = CC_SHA256($0, CC_LONG(data.count), &hash)
    }
    let outputData = Data(hash)
    return outputData.toHexString()
  }
  
  func hmac(keyString: String) -> Data {
    var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyString, keyString.count, self, self.count, &digest)
    let data = Data(digest)
    return data
  }
  
  func hmac(keyData: Data) -> Data {
    let keyBytes = keyData.bytes()
    let data = self.cString(using: String.Encoding.utf8)
    let dataLen = Int(self.lengthOfBytes(using: String.Encoding.utf8))
    var result = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes, keyData.count, data, dataLen, &result);
    
    return Data(result)
  }
}

private extension Data {
  func toHexString() -> String {
    let hexString = self.map{ String(format:"%02x", $0) }.joined()
    return hexString
  }
  
  func bytes() -> [UInt8] {
    let array = [UInt8](self)
    return array
  }
}
