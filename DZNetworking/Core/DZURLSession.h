//
//  DZURLSession.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>
#import "OMGHTTPURLRQ.h"

#ifdef DEBUG

#define DZLog(fmt,...) {\
NSLog((@"(%s - Line: %d) " fmt),__func__,__LINE__,##__VA_ARGS__);\
}

#else

#define DZLog(fmt,...) {}

#endif

#define DZPromise AnyPromise

extern NSString *const DZErrorDomain;
extern NSString *const DZErrorData;
extern NSString *const DZErrorResponse;
extern NSString *const DZErrorTask;

@interface DZURLSession : NSObject

/**
 *  A shared instance of DZURLSession. You can use this session or create your own.
 *
 *  @return DZURLSession.
 */
+ (instancetype)shared;

/**
 *  The base URL to use for all the requests. 
 *  example: https://api.twitter.com
 */
@property (nonatomic, copy) NSURL *baseURL;

/**
 *  The common HTTP Headers for all your requests. 
 *  example: Authentication or session headers.
 */
@property (nonatomic, copy) NSDictionary *HTTPHeaders;

/**
 *  The maximum HTTP Status code value to be treated as a success. All values above this will be treated as an error.
 *  example: 304;
 *  default: 399.
 */
@property (nonatomic, assign) NSUInteger maximumSuccessStatusCode;

/**
 *  Use the OMGUserAgent. Default is No.
 */
@property (nonatomic, assign) BOOL useOMGUserAgent;

/**
 *  Trigger a GET request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @return DZPromise
 */
- (DZPromise *)GET:(NSString *)URI
         parameters:(NSDictionary *)params;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 *  @return DZPromise
 */
- (DZPromise *)POST:(NSString *)URI
         parameters:(NSDictionary *)params;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 *  @return DZPromise
 */
- (DZPromise *)PUT:(NSString *)URI
        parameters:(NSDictionary *)params;

/**
 *  Trigger a PATCH request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *
 *  @return DZPromise
 */
- (DZPromise *)PATCH:(NSString *)URI
          parameters:(NSDictionary *)params;

/**
 *  Trigger a DELETE request. The response for such requests may not include a responseObject from the server. Check for the statusCode on the response object instead.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @return DZPromise
 */
- (DZPromise *)DELETE:(NSString *)URI
           parameters:(NSDictionary *)params;

/**
 *  Trigger a HEAD request. The response for such requests does not include a responseObject from the server. Check the response object for the desired information.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @return DZPromise
 */
- (DZPromise *)HEAD:(NSString *)URI
         parameters:(NSDictionary *)params;


/**
 *  Trigger a OPTIONS request. The response for such requests may not include a responseObject from the server. Check the response object for the desired information.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @return DZPromise
 */
- (DZPromise *)OPTIONS:(NSString *)URI
            parameters:(NSDictionary *)params;

@end
