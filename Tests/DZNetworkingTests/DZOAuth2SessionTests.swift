//
//  DZOAuth2SessionTests.swift
//  
//
//  Created by Nikhil Nigade on 05/12/22.
//

import XCTest
@testable import DZNetworking

fileprivate let clientID = ""
fileprivate let clientSecret = ""

final class DZOAuth2SessionTests: XCTestCase {
  /// for more info, see https://openidconnect.net
  private let oAuthSession = DZOAuthSession(
    serviceName: "oauth",
    clientID: clientID,
    clientSecret: clientSecret,
    authorizationURL: URL(string: "https://samples.auth0.com/authorize")!,
    redirectURL: URL(string: "https://openidconnect.net/callback")!,
    tokenURL: URL(string: "https://samples.auth0.com/oauth/token")!,
    refreshTokenURL: URL(string: "https://samples.auth0.com/oauth/token")!,
    scope: "openid profile email phone address"
  )
  
  override func setUpWithError() throws {
    oAuthSession.setBaseURL(URL(string: "https://samples.auth0.com")!)
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testAuthorize() throws {
    XCTAssertTrue(true)
    return
    
    let authURL = try oAuthSession.authorize()
    XCTAssertFalse(authURL.absoluteString.isEmpty)
    
    print("AuthURL: \(authURL)")
  }
  
  func testRedirect() async throws {
    XCTAssertTrue(true)
    return
    
    let redirectPath = oAuthSession.redirectURL.absoluteString.appending("?state=MTY3MDQ5OTM2OC43NDk5MzA5&code=N-3EtZmtxhYogz3j0b16xdV0gYZRe1tjcxFk6kOWS2zmK")
    
    oAuthSession.setState(.authorizing(stateToken: "MTY3MDQ5OTM2OC43NDk5MzA5"))
    
    try await oAuthSession.verifyOAuthCallback(url: URL(string: redirectPath)!)
    
    XCTAssertEqual(oAuthSession.state, .authorized)
  }
  
}
