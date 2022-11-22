//
//  FormURLEncodeTests.swift
//  
//
//  Created by Nikhil Nigade on 22/11/22.
//

import XCTest
@testable import DZNetworking

final class FormURLEncodeTests: XCTestCase {
  func testEncode1() throws {
    let input: [String : AnyHashable] = [
      "propStr1": "str1",
      "propStr2": "str2",
      "propArr1": ["arrStr1[]", "arrStr2"]
    ]
    let output = FormURLEncode(input)
    let expect = "propArr1[]=arrStr1%5B%5D&propArr1[]=arrStr2&propStr1=str1&propStr2=str2"
    XCTAssertEqual(output, expect)
  }
  
  func testEncode2() throws {
    let input = ["key": " !\"#$%&'()*+,/[]"]
    let output = FormURLEncode(input)
    let expect = "key=%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F%5B%5D"
    XCTAssertEqual(output, expect);
  }
  
  func testEncode3() throws {
    let input = ["key": ["key": "value"]]
    let output = FormURLEncode(input)
    let expect = "key[key]=value"
    XCTAssertEqual(output, expect)
  }
  
  func testEncode4() throws {
    let input = ["key": ["key": ["+": "value value", "-": ";"]]]
    let output = FormURLEncode(input);
    let expect = "key[key][%2B]=value%20value&key[key][-]=%3B"
    XCTAssertEqual(output, expect)
  }
  
  func testRequestURL1() throws {
    let value = " !\"#$%&'()*+,/"
    let request = try HTTPURLRQ.GET("http://example.com", query: ["key": value])
    let expect = "key=%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"
    
    XCTAssertNotNil(request.url)
    XCTAssertEqual(request.url!.query, expect)
  }
  
  func testRequestURL2() throws {
    let params = ["key": "%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F"]
    let request = try HTTPURLRQ.GET("http://example.com", query:params)
    let expect = "key=%2520%2521%2522%2523%2524%2525%2526%2527%2528%2529%252A%252B%252C%252F"
    
    XCTAssertNotNil(request.url)
    XCTAssertEqual(request.url!.query, expect)
  }
  
  func testRequestURL3() throws {
    let urlString = "http://example.com"
    let request = try HTTPURLRQ.GET(urlString)
    XCTAssertNotNil(request.url)
    XCTAssertNil(request.url!.query)
    XCTAssertEqual(request.url!.absoluteString, urlString)
  }
  
  func testBodyEncoding1() throws {
    let params = ["key": "value"]
    let request = try HTTPURLRQ.POST("http://example.com", json: params)
    
    let body = String(data: request.httpBody!, encoding: .utf8)
    let expect = "{\"key\":\"value\"}"
    XCTAssertEqual(expect, body, "Parameters were not encoded correctly");
  }
  
  func testBodyEncoding2() throws {
    let params = [["key": "value"]]
    let request = try HTTPURLRQ.POST("http://example.com", json: params)
    
    let body = String(data: request.httpBody!, encoding: .utf8)
    let expect = "[{\"key\":\"value\"}]"
    XCTAssertEqual(expect, body, "Parameters were not encoded correctly");
  }
}
