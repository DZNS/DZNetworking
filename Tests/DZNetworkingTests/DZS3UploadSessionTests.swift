//
//  DZS3UploadSessionTests.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import XCTest
@testable import DZNetworking

final class DZS3UploadSessionTests: XCTestCase {
  
  let bucket = "bucket"
  
  let session: DZS3UploadSession = {
    let session = DZS3UploadSession(
      credentials: .init(key: "foo", secret: "bar")
    )
    return session
  }()
  
  func testFileUpload() async throws {
    // run the test server and comment the two lines below
    XCTAssertTrue(true)
    return
    
    let filePath = ("~/tmp/sample.txt" as NSString).expandingTildeInPath
    
    guard let data = "Hello World, uploaded from DZURLSession".data(using: .utf8) else {
      throw CocoaError(.coderInvalidValue)
    }
    
    let fileURL = URL(fileURLWithPath: filePath)
    
    try data.write(to: fileURL)
    
    let (_, response) = try await session.upload(file: fileURL, bucket: bucket, path: "/tests/sample.txt", contentType: "text/plain")
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
}
