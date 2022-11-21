//
//  DZURLSessionTests.swift
//  
//
//  Created by Nikhil Nigade on 21/11/22.
//

import XCTest
@testable import DZNetworking

fileprivate struct Placeholder: Codable {
  let userID, id: Int
  let title, body: String
  
  enum CodingKeys: String, CodingKey {
    case userID = "userId"
    case id, title, body
  }
}

final class DZURLSessionTests: XCTestCase {
  
  let extraQueryParams = "userId=10&Auth=21bghdyu26%30"
  
  let session: DZURLSession = {
    let session = DZURLSession.shared
    session.baseURL = URL(string: "https://jsonplaceholder.typicode.com")
    session.responseParser = DZJSONResponseParser()
    return session
  }()
  
  let codableSession: DZURLSession = {
    let session = DZURLSession()
    session.baseURL = URL(string: "https://jsonplaceholder.typicode.com")
    return session
  }()
  
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if session.requestModifier == nil {
      session.requestModifier = { [weak self] request in
        guard let self else {
          return request
        }
        
        var uri = request.url?.absoluteString ?? ""
        if uri.contains("?") {
          // already have query params, append
          uri.append(self.extraQueryParams)
        }
        else {
          uri = uri.appendingFormat("?%@", self.extraQueryParams)
        }
        
        request.url = URL(string: uri)
        return request
      }
    }
  }
  
  // MARK: Async
  func testRequestModifier() async throws {
    let (_, response) = try await session.GET("/posts/1")
    XCTAssertTrue((response.url?.absoluteString ?? "").contains(extraQueryParams))
  }
  
  func testGET() async throws {
    let (result, _) = try await session.GET("/posts/1")
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testPOST() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1
    ]
    
    let (result, _) = try await session.POST("/posts", json: body)
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testPOSTWithQuery() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1
    ]
    
    let (result, _) = try await session.POST("/posts", query: ["app": "DZNetworking"], json: body)
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testPUT() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1,
      "id": 1
    ]
    
    let (result, _) = try await session.PUT("/posts/1", json: body)
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testPUTWithQuery() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1,
      "id": 1
    ]
    
    let (result, _) = try await session.PUT("/posts/1", query: ["app": "DZNetworking"], json: body)
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testPATCH() async throws {
    let (result, _) = try await session.PATCH("/posts/1", json: ["title": "baz"])
    
    guard let result = result as? [String: AnyHashable],
          let userID = result["userId"] as? Int else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(userID, 1)
  }
  
  func testDELETE() async throws {
    let (_, response) = try await session.DELETE("/posts/1", body: nil)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  func testHEAD() async throws {
    let (_, response) = try await session.HEAD("/posts")
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  func testOPTIONS() async throws {
    let (_, response) = try await session.OPTIONS("/posts")
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  // MARK: Codable
  func testGETCodable() async throws {
    // let (result, _) = try await session.GET("/posts/1")
    let (result, _) = try await codableSession.GET("/posts/1", type: Placeholder.self)
    
    guard let result else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(result.userID, 1)
  }
  
  func testPOSTCodable() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1
    ]
    
    let (result, _) = try await codableSession.POST("/posts", type: Placeholder.self, json: body)
    guard let result else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(result.userID, 1)
  }
  
  func testPUTCodable() async throws {
    let body: [String: AnyHashable] = [
      "title": "foo",
      "body": "bar",
      "userId": 1,
      "id": 1
    ]
    
    let (result, _) = try await codableSession.PUT("/posts/1", type: Placeholder.self, json: body)
    guard let result = result else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(result.userID, 1)
  }
  
  func testPATCHCodable() async throws {
    let (result, _) = try await codableSession.PATCH("/posts/1", type: Placeholder.self, json: ["title": "baz"])
    
    guard let result else {
      throw PublicError.invalidResponseType
    }
    
    XCTAssertEqual(result.userID, 1)
  }
  
  func testDELETECodable() async throws {
    let (_, response) = try await codableSession.DELETE("/posts/1", type: Placeholder.self, body: nil)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  func testHEADCodable() async throws {
    let (_, response) = try await codableSession.HEAD("/posts", type: Placeholder.self)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
  
  func testOPTIONSCodable() async throws {
    let (_, response) = try await codableSession.OPTIONS("/posts", type: Placeholder.self)
    
    XCTAssertLessThanOrEqual(response.statusCode, 204)
  }
}
