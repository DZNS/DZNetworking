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
+ (instancetype)shared;

@property (nonatomic, weak) id<DZURLSessionProtocol> delegate;

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
 *  The request modifier block, if provided, is called before the NSURLRequest is actually used in a request. You can utilize this block to add additional data to the request if required.
 *  An example could be, adding authentication query parameters to the URL which are dynamically generated (Flickr oAuth API).
 */
@property (nonatomic, copy) requestModifierBlock requestModifier;

/**
 *  The redirect modifier block, if provided, is called when a redirection is occuring. You can utilize this block to add additional data to the request if required or simply inspect it.
 */
@property (nonatomic, copy) redirectModifierBlock redirectModifier;

/**
 *  DZURLSession automatically uses the DZActivityIndicatorManager class by default to show a network activity indicator in the status bar. This is usually desired, however, in some usecases, this may be an undesired effect. The default value is YES, however, when initiating your DZURLSession object, you can set this to NO. During runtime, you can update this value to YES and all subsequent network requests will display the activityIndicator. This isn't recommended though because if you set it to NO afterwards, you may end up with a constantly spinning network activity indicator. Thus, it is strongly recommended you set this value when instansiating the session, and never touch it again. You can simply create a new session with an alternate value and use that where ever necessary.
 */
@property (nonatomic, assign) BOOL useActivityManager;

@property (nonatomic, strong) DZResponseParser *responseParser;

/**
 *  Trigger a GET request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *

 */
- (void)GET:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)POST:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a POST request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)POST:(NSString *)URI queryParams:(NSDictionary *)query parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)PUT:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a PUT request
 *
 *  @param URI    The URI for the request
 *  @param query  Parameters for the URL query.
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)PUT:(NSString *)URI queryParams:(NSDictionary *)query parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a PATCH request
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)PATCH:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a DELETE request. The response for such requests may not include a responseObject from the server. Check for the statusCode on the response object instead.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the HTTP Body.
 *

 */
- (void)DELETE:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Trigger a HEAD request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests does not include a responseObject from the server. Check the response object for the desired information.

 */
- (void)HEAD:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;


/**
 *  Trigger a OPTIONS request.
 *
 *  @param URI    The URI for the request
 *  @param params Parameters for the request. These will be included in the URL as query parameters.
 *
 *  @discussion The response for such requests may not include a responseObject from the server. Check the response object for the desired information.

 */
- (void)OPTIONS:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

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
- (NSURLRequest *)requestWithURI:(NSString *)URI method:(NSString *)method params:(NSDictionary *)params;

/**
 *  Build an NSURLRequest using requestWithURI:method:params and then trigger that request.
 *
 *  @param URI    the URI for the request
 *  @param method The HTTP request method to be used for the request.
 *  @param params For PUT, POST, PATCH and DELETE requests, the params will be set on the HTTPBody. For all other request types, the parameters will be set on the query.
 *
 */
- (void)performRequestWithURI:(NSString *)URI method:(NSString *)method params:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Triggers network request with the provided NSURLRequest. This method is the final method that gets called from most of the above methods. You should never have to call this method directly, but if you need to, ensure your parameters are correctly encoded and the required HTTPMethod is set.
 *
 *  @param request The request object
 *
 */
- (void)requestWithReq:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB;

#pragma mark - 

// The following methods make two assumptions:
// 1. The NSURLRequest is valid, and ready to be fired.
// 2. The NSURLRequest will not be run through the requestModifier block. If you need to, you must do that before passing it here.
//
// The following methods will however:
// 1. Correctly set the HTTPMethod for you incase it is incorrect.

- (void)GET:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)PUT:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)POST:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)PATCH:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)DELETE:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)OPTIONS:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;
- (void)HEAD:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB;

@end
