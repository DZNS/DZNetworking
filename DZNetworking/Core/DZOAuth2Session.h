//
//  DZOAuth2Session.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 31/05/19.
//  Copyright © 2019 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DZURLSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface DZOAuth2Session : NSObject {
@public
    NSString *_state;
}

- (instancetype)initWithClientID:(NSString * _Nonnull)clientID
                    clientSecret:(NSString * _Nonnull)clientSecret
                     serviceName:(NSString * _Nonnull)serviceName
                authorizationURL:(NSString * _Nonnull)authorizationURL
                        tokenURL:(NSString * _Nonnull)tokenURL
                     redirectURL:(NSString * _Nonnull)redirectURL
                         baseURL:(NSURL * _Nonnull)baseURL 
                           scope:(NSString * _Nonnull)scope;

@property (nonatomic, copy) NSURL *baseURL;

@property (nonatomic, copy, readonly) NSString *token;

@property (nonatomic, copy, readonly) NSString *tokenID;

@property (nonatomic, copy, readonly) NSString * _Nonnull scope;

- (NSURL *)authorize;

- (void)verifyOAuthCallback:(NSURL *)url
                    success:(void(^ _Nullable)(void))successCB
                      error:(void(^ _Nullable)(NSError * error))errorCB;

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
- (NSURLSessionTask *)GET:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)POST:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)PUT:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a PATCH request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)PATCH:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a DELETE request. The response for such requests may not include a responseObject from the server. Check for the statusCode on the response object instead.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 */
- (NSURLSessionTask *)DELETE:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a HEAD request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests does not include a responseObject from the server. Check the response object for the desired information.
 */
- (NSURLSessionTask *)HEAD:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;


/**
 *  Trigger a OPTIONS request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests may not include a responseObject from the server. Check the response object for the desired information.
 */
- (NSURLSessionTask *)OPTIONS:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nonnull)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;


@end

NS_ASSUME_NONNULL_END
