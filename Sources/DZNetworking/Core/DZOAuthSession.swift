//
//  DZOAuthSession.swift
//  
//
//  Created by Nikhil Nigade on 07/12/22.
//

import Foundation

enum OAuthError: LocalizedError {
  /// an auth session is already in progress
  case activeAuthState
  /// an invalid or no state token was received in the oauth verification callback
  case invalidOrNoStateVerification
  /// an invalid or no code  was received in the oauth verification callback
  case invalidOrNoCode
  /// got an invalid response when fetching the tokens
  case invalidTokenResponse
  /// session should be authorized before its tokens can be refreshed
  case invalidStateForRefreshing
}

final class DZOAuthSession: NSObject {
  enum SessionState: Equatable {
    case none
    case authorizing(stateToken: String)
    case authorized
    case refreshing
  }
  
  public let serviceName: String
  
  public let clientID: String
  private let clientSecret: String
  
  public var token: String? = nil
  public var tokenID: String? = nil
  public var refreshToken: String? = nil
  
  public let authorizationURL: URL
  public let redirectURL: URL
  public let tokenURL: URL
  public let refreshTokenURL: URL
  
  public var scope: String = ""
  
  private(set) public lazy var session: DZURLSession = {
    let session = DZURLSession()
    session.responseParser = DZJSONResponseParser()
    session.requestModifier = { [weak self] request in
      guard let self, let token = self.token else {
        return request
      }
      
      let bearer = String(format: "Bearer %@", token)
      request.setValue(bearer, forHTTPHeaderField: "Authorization")
      
      return request
    }
    
    return session
  }()
  
  public var accountName: String? = nil
  public var username: String? {
    accountName ?? tokenID
  }
  
  private(set) public var state: SessionState = .none
  
  internal init(serviceName: String, clientID: String, clientSecret: String, authorizationURL: URL, redirectURL: URL, tokenURL: URL, refreshTokenURL: URL, scope: String = "") {
    self.serviceName = serviceName
    self.clientID = clientID
    self.clientSecret = clientSecret
    self.authorizationURL = authorizationURL
    self.redirectURL = redirectURL
    self.tokenURL = tokenURL
    self.refreshTokenURL = refreshTokenURL
    self.scope = scope
  }
  
  /// Beings an authorization flow
  /// - Returns: the `URL` for authorizing a user in a browser session
  public func authorize() throws -> URL {
    guard self.state == .none else {
      throw OAuthError.activeAuthState
    }
    
    let stateToken = "\(Date().timeIntervalSince1970)".data(using: .utf8)!.base64EncodedString()
    state = .authorizing(stateToken: stateToken)
    
    let params: [String: String] = [
      "response_type": "code",
      "client_id": clientID,
      "redirect_uri": redirectURL.absoluteString,
      "scope": scope,
      "state": stateToken,
      "access_type": "offline",
      "prompt": "consent"
    ]
    
    let request = try HTTPURLRQ.GET(authorizationURL.absoluteString, query: params)
    return request.url!
  }
  
  /// verify OAuth params from callback URL and update state
  /// - Parameter url: URL on which the callback was recieved (eg. `appname://oauth_verify?...`
  public func verifyOAuthCallback(url: URL) async throws {
    guard let components = URLComponents(string: url.absoluteString),
          let receivedToken = components.queryItems?.first(where: { $0.name == "state" })?.value,
          case let .authorizing(stateToken) = state,
          stateToken == receivedToken else {
      state = .none
      throw OAuthError.invalidOrNoStateVerification
    }
    
    guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
      state = .none
      throw OAuthError.invalidOrNoCode
    }
    
    let body: [String: String] = [
      "grant_type": "authorization_code",
      "client_id": clientID,
      "client_secret": clientSecret,
      "redirect_uri": redirectURL.absoluteString,
      "code": code
    ]
    
    let (result, _) = try await session.POST(tokenURL.absoluteString, query: [:], json: body)
    
    guard let json = result as? [String: Any],
          let token = json["access_token"] as? String else {
      state = .none
      throw OAuthError.invalidTokenResponse
    }
    
    self.token = token
    self.tokenID = json["id_token"] as? String
    self.refreshToken = json["refresh_token"] as? String
    
    self.state = .authorized
  }
  
  /// Refresh tokens using an existing refresh token when the current token becomes invalid 
  func refreshTokens() async throws {
    guard state == .authorized,
          let refreshToken else {
      throw OAuthError.invalidStateForRefreshing
    }
    
    state = .refreshing
    
    let body: [String: String] = [
      "refresh_token": refreshToken,
      "client_id": clientID,
      "client_secret": clientSecret,
      "grant_type": "refresh_token"
    ]
    
    let (result, _) = try await session.POST(refreshTokenURL.absoluteString, query: [:], json: body)
    
    guard let json = result as? [String: Any],
          let token = json["access_token"] as? String else {
      self.state = .authorized
      throw OAuthError.invalidTokenResponse
    }
    
    self.token = token
    
    self.state = .authorized
  }
  
  public func setBaseURL(_ url: URL) {
    guard session.baseURL != url else {
      return
    }
    
    session.baseURL = url
  }
}

#if DEBUG || TEST
extension DZOAuthSession {
  func setState(_ state: SessionState) {
    self.state = state
  }
}
#endif
