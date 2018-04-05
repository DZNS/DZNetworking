//
//  DZOAuthSession.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 10/2/15.
//  Copyright © 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZURLSession.h"

@interface DZOAuthSession : NSObject

/**
 *  The DZURLSession interally used by DZOAuthSession.
 */
@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session;

/**
 *  The base URL for the OAuth Service Provider
 */
@property (nonatomic, copy, readonly) NSURL * _Nonnull baseURL;

/**
 *  This client supports oAuth version 1.0 Rev A (RFC 5849)
 */
@property (nonatomic, readonly) NSString * _Nonnull oAuthVersion;

/**
 *  The URL from which you'll request the user Authorization URL. Set this, followed by calling beginOAuthWithCompletion:.
 */
@property (nonatomic, copy) NSURL * _Nonnull requestTokenURL;

/**
 *  If the request to beginOAuthWithCompletion: succeeds, the userAuthorizationURL will have the value which you should open in a browser.
 */
@property (nonatomic, copy) NSURL * _Nullable userAuthorizationURL;

/**
 *  The URL which you'll use to fetch the accessToken for the user.
 */
@property (nonatomic, copy) NSURL * _Nullable accessTokenURL;

/**
 *  The access token received by the consumer (your app) once the entire authorization chain has been completed.
 */
@property (nonatomic, copy) NSString * _Nullable accessToken;

@property (nonatomic, copy) NSString * _Nullable accessSecret;

/**
 *  Set this to something like `myapp://oauth` if you're handling the response in your app. If you're handling the response on your server, set it to that URL.
 */
@property (nonatomic, copy) NSString * _Nonnull oAuthCallback;

/**
 *  Your consumer key A.K.A. Application Key
 */
@property (nonatomic, copy, readonly) NSString * _Nonnull consumerKey;

/**
 *  Your consumer secret, A.K.A. Application Secret
 */
@property (nonatomic, copy, readonly) NSString * _Nonnull consumerSecret;

#pragma mark - Overrides

/**
 *  A list of extra paramaters to include in every outgoing request. It's recommended you set a static dictionary as the return value to reduce overhead as this can be called multiple times. The core implementation returns an empty dictionary. If you need to pass common parameters, override this method in your subclass and do not call super.
 *
 *  @return A NSDictionary of common parameters.
 */
- (NSDictionary *_Nonnull)commonParameters;

/**
 *  Subclasses should implement this method and return the appropriate signing key. Do not call super from your method.
 *
 *  @return The signing key. (this could be contextual)
 */
- (NSString *_Nonnull)signingKey;

#pragma mark -

- (instancetype _Nullable)initWithConsumerKey:(NSString *_Nonnull)consumerKey
                               consumerSecret:(NSString *_Nonnull)consumerSecret
                                      baseURL:(NSURL *_Nonnull)baseURL;


- (void)beginAuthWithAdditionParams:(NSDictionary *_Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)finishAuthWithToken:(NSString * _Nonnull)token verifier:(NSString * _Nonnull)verifier success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - HTTP

/**
 *  The HTTP Verb methods call `signURL:method:parameters:` if appropriate parameters aren't already set. It's recommended you call these methods instead of directly calling `signURL:method:parameters:`.
 */


/**
 *  Trigger a GET request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 */
- (void)GET:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)POST:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)POST:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)PUT:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)PUT:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PATCH request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)PATCH:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a DELETE request. The response for such requests may not include a responseObject from the server. Check for the statusCode on the response object instead.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (void)DELETE:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a HEAD request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests does not include a responseObject from the server. Check the response object for the desired information.
 */
- (void)HEAD:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;


/**
 *  Trigger a OPTIONS request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests may not include a responseObject from the server. Check the response object for the desired information.
 */
- (void)OPTIONS:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nonnull)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;


#pragma mark - Internal Methods

- (NSDictionary *_Nullable)sign:(id _Nonnull)URI
                         method:(NSString *_Nonnull)method
                     parameters:(NSDictionary *_Nullable)params;

@end
