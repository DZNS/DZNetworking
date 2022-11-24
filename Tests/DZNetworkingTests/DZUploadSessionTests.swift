//
//  DZUploadSessionTests.swift
//  
//
//  Created by Nikhil Nigade on 24/11/22.
//

import XCTest
@testable import DZNetworking

final class DZUploadSessionTests: XCTestCase {
  
  let session: DZUploadSession = {
    let session = DZUploadSession.shared
    session.session.baseURL = URL(string: "http://localhost:3000")
    session.session.responseParser = DZJSONResponseParser()
    return session
  }()
  
  func testDataUpload() async throws {
    // run the test server and comment the two lines below
    XCTAssertTrue(true)
    return
    
    guard let data = "This is some text".data(using: .utf8) else {
      throw CocoaError(.coderInvalidValue)
    }
    
    let (_, response) = try await session.upload(data: data, fileName: "tests.txt", fieldName: "file", uri: "/files", query: nil)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  func testFileUpload() async throws {
    // run the test server and comment the two lines below
    XCTAssertTrue(true)
    return
    
    let filePath = ("~/tmp/sample.txt" as NSString).expandingTildeInPath
    
    guard let data = "This is some text".data(using: .utf8) else {
      throw CocoaError(.coderInvalidValue)
    }
    
    let fileURL = URL(fileURLWithPath: filePath)
    
    try data.write(to: fileURL)
    
    let (_, response) = try await session.upload(file: fileURL, fieldName: "file", uri: "/files", query: nil)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
}
