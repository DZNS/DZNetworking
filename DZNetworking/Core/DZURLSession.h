//
//  DZURLSession.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

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

- (DZPromise *)GET:(NSString *)URI
         parameters:(NSDictionary *)params;

- (DZPromise *)POST:(NSString *)URI
         parameters:(NSDictionary *)params;

- (DZPromise *)PUT:(NSString *)URI
        parameters:(NSDictionary *)params;

- (DZPromise *)PATCH:(NSString *)URI
          parameters:(NSDictionary *)params;

- (DZPromise *)DELETE:(NSString *)URI
           parameters:(NSDictionary *)params;

- (DZPromise *)HEAD:(NSString *)URI
         parameters:(NSDictionary *)params;

- (DZPromise *)OPTIONS:(NSString *)URI
            parameters:(NSDictionary *)params;

@end
