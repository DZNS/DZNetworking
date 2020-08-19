//
//  DZURLSession.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//
//  The MIT License (MIT)
//
// Copyright (c) 2015 Dezine Zync Studios
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <DZNetworking/DZCommon.h>
#import <DZNetworking/DZResponseParser.h>

/**
 *  The base class for all REST API networking. This class should satisfy all your REST API networking requirements. If you believe we've missed something, or perhaps something needs fixing, please open an issue/pull request on github: https://github.com/dzns/DZNetworking
 */
@interface DZURLSession : NSObject

/**
 *  A shared instance of DZURLSession. You can use this session or create your own.
 *
 *  @return DZURLSession.
 */
+ (instancetype _Nonnull)shared;

@property (readonly, nonatomic, strong) NSURLSessionConfiguration * _Nonnull sessionConfiguration;
@property (readonly, nonatomic, strong) NSOperationQueue * _Nonnull operationQueue;
@property (readwrite, nonatomic, weak) id <NSURLSessionDataDelegate> _Nullable delegate;

@property (nonatomic, assign) BOOL isBackgroundSession;

- (instancetype _Nonnull)initWithSessionConfiguration:(NSURLSessionConfiguration * _Nonnull )config;

- (instancetype _Nonnull)initWithSessionConfiguration:(NSURLSessionConfiguration * _Nonnull )config delegate:(id<DZURLSessionProtocol> _Nullable)delegate queue:(NSOperationQueue * _Nonnull)queue;

- (instancetype _Nonnull )init;

/**
 *  The base URL to use for all the requests. 
 *  example: https://api.twitter.com
 */
@property (nonatomic, copy) NSURL * _Nullable baseURL;

/**
 *  The common HTTP Headers for all your requests. 
 *  example: Authentication or session headers.
 */
@property (nonatomic, copy) NSDictionary * _Nullable HTTPHeaders;

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
 *  The request modifier block, if provided, is called before the NSURLRequest is actually used in a request. You can utilize this block to add additional data to the request if required.
 *  An example could be, adding authentication query parameters to the URL which are dynamically generated (Flickr oAuth API).
 */
@property (nonatomic, copy) requestModifierBlock _Nullable requestModifier;

/**
 *  The redirect modifier block, if provided, is called when a redirection is occuring. You can utilize this block to add additional data to the request if required or simply inspect it.
 */
@property (nonatomic, copy) redirectModifierBlock _Nullable redirectModifier;

/**
 *  DZURLSession automatically uses the DZActivityIndicatorManager class by default to show a network activity indicator in the status bar. This is usually desired, however, in some usecases, this may be an undesired effect. The default value is YES, however, when initiating your DZURLSession object, you can set this to NO. During runtime, you can update this value to YES and all subsequent network requests will display the activityIndicator. This isn't recommended though because if you set it to NO afterwards, you may end up with a constantly spinning network activity indicator. Thus, it is strongly recommended you set this value when instansiating the session, and never touch it again. You can simply create a new session with an alternate value and use that where ever necessary.
 */
@property (nonatomic, assign) BOOL useActivityManager;

@property (nonatomic, strong) DZResponseParser * _Nullable responseParser;

#pragma mark -

- (NSString * _Nonnull)stringifyQueryParams:(NSDictionary * _Nullable)queryParams;

/**
 *  Trigger a GET request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 */
- (NSURLSessionTask * _Nullable)GET:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)POST:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)POST:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)PUT:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)PUT:(NSString * _Nonnull)URI queryParams:(NSDictionary * _Nullable)query parameters:(NSDictionary * _Nullable)params success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

/**
 *  Trigger a PATCH request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)PATCH:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nonnull)errorCB;

/**
 *  Trigger a DELETE request. The response for such requests may not include a responseObject from the server. Check for the statusCode on the response object instead.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (NSURLSessionTask * _Nullable)DELETE:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Trigger a HEAD request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests does not include a responseObject from the server. Check the response object for the desired information.

 */
- (NSURLSessionTask * _Nullable)HEAD:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;


/**
 *  Trigger a OPTIONS request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests may not include a responseObject from the server. Check the response object for the desired information.

 */
- (NSURLSessionTask * _Nullable)OPTIONS:(NSString * _Nonnull)URI parameters:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - 

/**
 *  Build an NSURLRequest with the provided information.
 *
 *  @param URI    the URI for the request
 *  @param method The HTTP request method to be used for the request.
 *  @param params For PUT, POST, PATCH and DELETE requests, the params will be set on the HTTPBody. For all other request types, the parameters will be set on the query.
 *
 *  @return NSURLRequest
 */
- (NSURLRequest * _Nullable)requestWithURI:(NSString * _Nonnull)URI method:(NSString * _Nullable)method params:(NSDictionary * _Nullable)params;

/**
 *  Build an NSURLRequest using requestWithURI:method:params and then trigger that request.
 *
 *  @param URI    the URI for the request
 *  @param method The HTTP request method to be used for the request.
 *  @param params For PUT, POST, PATCH and DELETE requests, the params will be set on the HTTPBody. For all other request types, the parameters will be set on the query.
 *
 */
- (NSURLSessionTask * _Nullable)performRequestWithURI:(NSString * _Nonnull)URI method:(NSString * _Nonnull)method params:(NSDictionary * _Nullable)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

/**
 *  Triggers network request with the provided NSURLRequest. This method is the final method that gets called from most of the above methods. You should never have to call this method directly, but if you need to, ensure your parameters are correctly encoded and the required HTTPMethod is set.
 *
 *  @param request The request object
 *
 */
- (NSURLSessionTask * _Nullable)requestWithReq:(NSURLRequest * _Nonnull)request success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - 

// The following methods make two assumptions:
// 1. The NSURLRequest is valid, and ready to be fired.
// 2. The NSURLRequest will not be run through the requestModifier block. If you need to, you must do that before passing it here.
//
// The following methods will however:
// 1. Correctly set the HTTPMethod for you incase it is incorrect.

- (NSURLSessionTask * _Nullable)GET:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)PUT:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)POST:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)PATCH:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)DELETE:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)OPTIONS:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;
- (NSURLSessionTask * _Nullable)HEAD:(NSURLRequest * _Nonnull)req success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Background Sessions

@property (nonatomic, copy, nullable) void (^backgroundCompletionHandler)(void);

@property (nonatomic, strong, nonnull) NSMutableDictionary <NSNumber *, successBlock> *  backgroundSuccessBlocks;

@property (nonatomic, strong, nonnull) NSMutableDictionary <NSNumber *, errorBlock> * backgroundErrorBlocks;

@end
