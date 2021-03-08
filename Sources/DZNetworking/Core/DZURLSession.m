//
//  DZURLSession.m
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

#import "DZURLSession.h"
#if TARGET_OS_IOS == 1
#import "../Utilities/DZActivityIndicatorManager.h"
#endif

#import "../Vendors/OMGHTTPURLRQ.h"

#ifndef weakify
#define weakify(var) __weak typeof(var) AHKWeak_##var = var;
#endif

#ifndef strongify
#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = AHKWeak_##var; \
_Pragma("clang diagnostic pop")
#endif

#ifndef NSFoundationVersionNumber_iOS_8_0
    #define NSFoundationVersionNumber_With_Fixed_5871104061079552_bug 1140.11
#else
    #define NSFoundationVersionNumber_With_Fixed_5871104061079552_bug NSFoundationVersionNumber_iOS_8_0
#endif

// The following lines of code are taken from AFNetworking/AFURLSessionManager.m
static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t dz_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dz_url_session_manager_processing_queue = dispatch_queue_create("com.dezinezync.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return dz_url_session_manager_processing_queue;
}

@interface DZURLSession() <NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSMutableData *> * backgroundResponseData;

@end

@implementation DZURLSession

+ (instancetype)shared
{
    
    static dispatch_once_t onceToken;
    static DZURLSession *dzsession = nil;
    dispatch_once(&onceToken, ^{
        
        dzsession = [[DZURLSession alloc] init];
        
    });
    
    return dzsession;
    
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)config {
    
    if (self = [super init]) {
        
        _maximumSuccessStatusCode = 399;
        
        _sessionConfiguration = config;
        _delegate = self;
        
        _useActivityManager = YES;
        
        _backgroundSuccessBlocks = [NSMutableDictionary new];
        _backgroundErrorBlocks = [NSMutableDictionary new];
        _backgroundResponseData = [NSMutableDictionary new];
        
    }
    
    return self;
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)config delegate:(id<DZURLSessionProtocol>)delegate queue:(NSOperationQueue *)queue {
    
    if (self = [super init]) {
        
        _maximumSuccessStatusCode = 399;
        
        _sessionConfiguration = config;
        _operationQueue = queue;
        _delegate = delegate;
        
        _useActivityManager = YES;
        _backgroundResponseData = [NSMutableDictionary new];
        
    }
    
    return self;
}

- (instancetype)init
{

    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfig.HTTPMaximumConnectionsPerHost = 5;
    defaultConfig.timeoutIntervalForRequest = 15;
    
    self = [self initWithSessionConfiguration:defaultConfig];
    
    return self;
    
}

#pragma mark - Session Getter

- (NSURLSession *)session {
    if (_session == nil) { @autoreleasepool {
        _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self.delegate delegateQueue:self.operationQueue];
    } }
    
    return _session;
}

- (NSOperationQueue *)operationQueue {
    
    if (_operationQueue == nil) {
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = self.isBackgroundSession == YES ? 1 : 5;
        
        _operationQueue = queue;
        
    }
    
    return _operationQueue;
    
}

#pragma mark - HTTP Methods

- (NSString *)stringifyQueryParams:(NSDictionary *)queryParams {
    
    if (!queryParams) {
        return @"";
    }
    
    return OMGFormURLEncode(queryParams);
    
}

- (NSURLSessionTask *)GET:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"GET" params:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSString *)URI
                parameters:(NSDictionary *)params
                   success:(successBlock)successCB
                     error:(errorBlock)errorCB
{
    
    return [self POST:URI queryParams:nil parameters:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSString *)URI
               queryParams:(NSDictionary *)query
                parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{

    if(query)
    {
        NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
        
        id queryString = OMGFormURLEncode(query);
        if (queryString)
            url = [url stringByAppendingFormat:@"?%@", queryString];
        
        NSMutableURLRequest *req = [OMGHTTPURLRQ POST:url :params error:nil];
        
        if(self.requestModifier)
        {
            req = self.requestModifier(req);
        }
        
        return [self requestWithReq:req success:successCB error:errorCB];
    }
    else
    {
        return [self performRequestWithURI:URI method:@"POST" params:params success:successCB error:errorCB];
    }
    
}

- (NSURLSessionTask *)PUT:(NSString *)URI
               parameters:(NSDictionary *)params
                  success:(successBlock)successCB
                    error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"PUT" params:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PUT:(NSString *)URI
              queryParams:(NSDictionary *)query
               parameters:(NSDictionary *)params
                  success:(successBlock)successCB
                    error:(errorBlock)errorCB
{
    
    if(query)
    {
        NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
        
        id queryString = OMGFormURLEncode(query);
        if (queryString) {
            url = [url stringByAppendingFormat:@"?%@", queryString];
        }
        
        NSMutableURLRequest *req = [OMGHTTPURLRQ PUT:url JSON:params error:nil];
        
        if(self.requestModifier)
        {
            req = [self.requestModifier(req) mutableCopy];
        }
        
        return [self requestWithReq:req.copy success:successCB error:errorCB];
    }
    else
    {
        return [self performRequestWithURI:URI method:@"PUT" params:params success:successCB error:errorCB];
    }
    
}

- (NSURLSessionTask *)PATCH:(NSString *)URI
                 parameters:(NSDictionary *)params
                    success:(successBlock)successCB
                      error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"PATCH" params:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)DELETE:(NSString *)URI
                  parameters:(NSDictionary *)params
                     success:(successBlock)successCB
                       error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"DELETE" params:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)HEAD:(NSString *)URI
                parameters:(NSDictionary *)params
                   success:(successBlock)successCB
                     error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"HEAD" params:params success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)OPTIONS:(NSString *)URI
                   parameters:(NSDictionary *)params
                      success:(successBlock)successCB
                        error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"OPTIONS" params:params success:successCB error:errorCB];
    
}

#pragma mark - 

- (NSURLSessionTask *)GET:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"GET" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PUT:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"PUT" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)POST:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"POST" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)PATCH:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"PATCH" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)DELETE:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"DELETE" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)OPTIONS:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"OPTIONS" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (NSURLSessionTask *)HEAD:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"HEAD" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

#pragma mark - Internal

- (NSURLRequest *)ensureHTTPMethod:(NSString *)method
                         onRequest:(NSURLRequest *)request
{
    
    if(![request.HTTPMethod isEqualToString:method])
    {
        
        NSMutableURLRequest *req = request.mutableCopy;
        req.HTTPMethod = method;
        
        request = req.copy;
        
    }
    
    return request;
    
}

- (NSURLRequest *)requestWithURI:(NSString *)URI
                       method:(NSString *)method
                       params:(NSDictionary *)params {
    
    NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
    
    NSMutableURLRequest *mutableRequest;
    
    if([method isEqualToString:@"GET"])
    {
        mutableRequest = [OMGHTTPURLRQ GET:url :params error:nil];
    }
    else if([method isEqualToString:@"POST"])
    {
        mutableRequest = [OMGHTTPURLRQ POST:url JSON:params ?: @{} error:nil];
    }
    else if([method isEqualToString:@"PUT"])
    {
        mutableRequest = [OMGHTTPURLRQ PUT:url JSON:params error:nil];
    }
    else if([method isEqualToString:@"DELETE"])
    {
        mutableRequest = [OMGHTTPURLRQ DELETE:url :params error:nil];
    }
    else
    {
        mutableRequest = [OMGHTTPURLRQ GET:url :params error:nil];
        mutableRequest.HTTPMethod = method;
    }
    
    if(self.requestModifier) {
        
        mutableRequest = self.requestModifier(mutableRequest);
        
        if(mutableRequest == nil)
        {
            
            NSError *modifierError = [[NSError alloc] initWithDomain:DZErrorDomain code:DZUnusableRequestError userInfo:nil];
            
            @throw modifierError;
            
        }
        
    }
    
    NSURLRequest *request = mutableRequest.copy;
    
    /*
     * sanitize the URL request.
     * 1. the URL shouldn't have a ? if there are no searchParams
     */
    if (!params
        || ([params isKindOfClass:NSDictionary.class] && params.allKeys.count == 0)
        || ([params isKindOfClass:NSArray.class] && params.count == 0)) {
        
        NSString *uri = mutableRequest.URL.absoluteString;
        if (uri.length && [[uri substringFromIndex:uri.length-1] isEqualToString:@"?"]) {
            uri = [uri substringToIndex:uri.length-1];
            
            mutableRequest.URL = [NSURL URLWithString:uri];
            
            request = mutableRequest.copy;
        }
        
    }
    
    return request;
    
}

- (NSURLSessionTask *)performRequestWithURI:(NSString *)URI
                                     method:(NSString *)method
                                     params:(NSDictionary *)params
                                    success:(successBlock)successCB
                                      error:(errorBlock)errorCB
{
    
    NSURLRequest *req = [self requestWithURI:URI method:method params:params];
    
    return [self requestWithReq:req success:successCB error:errorCB];
}

- (NSURLSessionTask *)performRequestWithURI:(NSString *)URI
                                     method:(NSString *)method
                                      query:(NSDictionary *)query
                                     body:(NSDictionary *)body
                                    success:(successBlock)successCB
                                      error:(errorBlock)errorCB {
    
    NSURL *url = [NSURL URLWithString:URI];
    
    if (query != nil) {
        
        // append to query components
        NSURLComponents *comps = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        comps.queryItems = @[];
        
        for (NSString *key in query.allKeys) {
            
            comps.queryItems = [comps.queryItems arrayByAddingObject:[NSURLQueryItem queryItemWithName:key value:query[key]]];
            
        }
        
        url = comps.URL;
        
    }
    
    id params = body;
    
    NSURLRequest *req = [self requestWithURI:url.absoluteString method:method params:params];
    
    return [self requestWithReq:req success:successCB error:errorCB];
}

- (NSURLSessionTask *)requestWithReq:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB
{
    __block NSURLSessionDataTask *task = nil;
    
    if (self.isBackgroundSession == YES) {
        
        task = (NSURLSessionDataTask *)[self.session downloadTaskWithRequest:request];
        
    }
    else {
        
        task = [self.session dataTaskWithRequest:request];
        
    }
    
    if (task != nil) {
        
        if (successCB) {
//#ifdef DEBUG
//            NSLog(@"Added successCB for task:%@", @(task.taskIdentifier));
//#endif
            
            [self.backgroundSuccessBlocks setObject:[successCB copy] forKey:@(task.taskIdentifier)];
        }
        
        if (errorCB) {
//#ifdef DEBUG
//            NSLog(@"Added errorCB for task:%@", @(task.taskIdentifier));
//#endif
            [self.backgroundErrorBlocks setObject:[errorCB copy] forKey:@(task.taskIdentifier)];
        }
        
        [task resume];
        
#if TARGET_OS_IOS == 1
        if(self.useActivityManager) {
            [[DZActivityIndicatorManager shared] incrementCount];
        }
#endif
        
    }
    
    return task;
}

- (void)invalidateSessionCancelingTasks:(BOOL)cancelPendingTasks {
    if (cancelPendingTasks) {
        [self.session invalidateAndCancel];
    } else {
        [self.session finishTasksAndInvalidate];
    }
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, session: %@, operationQueue: %@>", NSStringFromClass([self class]), self, self.session, self.operationQueue];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    if (error) {
#ifdef DEBUG
        NSLog(@"[DZURLSession] Session Invalidation: %@", [error description]);
#endif
    }
    
    if (session == self.session) {
        
        self.backgroundResponseData = [NSMutableDictionary new];
        self.backgroundErrorBlocks = [NSMutableDictionary new];
        self.backgroundSuccessBlocks = [NSMutableDictionary new];
        
        [self invalidateSessionCancelingTasks:YES];
        
    }
    
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    
    if(self.delegate && self.delegate != self && [self.delegate respondsToSelector:@selector(URLSession:didReceiveChallenge:completionHandler:)])
    {
        [self.delegate URLSession:session didReceiveChallenge:challenge completionHandler:completionHandler];
    }
    else
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)redirectResponse newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    
    NSURLRequest *newRequest = request;
    
    if (self.redirectModifier) {
        newRequest = self.redirectModifier(task, request, redirectResponse);
    }
    
    completionHandler(newRequest);
    
}

#pragma mark - Background Tasks

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask {
    
    NSLog(@"Task %@ became a download task", @(dataTask.taskIdentifier));
    
}

#pragma mark - Handling Responses

/// Single processor method for handling data and download tasks.
/// @param task The Task for which to handle processing for.
/// @param data The response data, if any.
/// @param error An error, if any, that has occurred when processing the request.
- (void)handleResponseFor:(NSURLSessionTask * _Nonnull)task responseData:(NSData * _Nullable)data error:(NSError * _Nullable)error {
    
#if TARGET_OS_IOS == 1
    if (self.isBackgroundSession == NO) {
        // we simply decrement it. No harm, since we ensure the value never drops below 0.
        [[DZActivityIndicatorManager shared] decrementCount];
    }
#endif
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[task response];
        
    errorBlock errorBlock = [self.backgroundErrorBlocks objectForKey:@(task.taskIdentifier)];
    successBlock successBlock = [self.backgroundSuccessBlocks objectForKey:@(task.taskIdentifier)];
    
    if (errorBlock) {
        
//#ifdef DEBUG
//        NSLog(@"Got errorCB for task:%@", @(task.taskIdentifier));
//#endif
        
        errorBlock = [errorBlock copy];
        
        [self.backgroundErrorBlocks removeObjectForKey:@(task.taskIdentifier)];
        
//#ifdef DEBUG
//        NSLog(@"Removed errorCB from dictionary for task:%@", @(task.taskIdentifier));
//#endif
        
    }
    
    if (successBlock) {
        
//#ifdef DEBUG
//        NSLog(@"Got successCB for task:%@", @(task.taskIdentifier));
//#endif
        
        successBlock = [successBlock copy];
        
        [self.backgroundSuccessBlocks removeObjectForKey:@(task.taskIdentifier)];
        
//#ifdef DEBUG
//        NSLog(@"Removed successCB from dictionary for task:%@", @(task.taskIdentifier));
//#endif
        
    }
    
    if (error != nil) {
        
        if (errorBlock) {
            
            dispatch_async(dispatch_get_main_queue(), ^{

                errorBlock(error, (NSHTTPURLResponse *)[task response], task);

            });
            
        }
        
        return;
        
    }
    
    if (response.statusCode != 304) {
        
        if (data != nil ) {
            
            weakify(self);
                       
           dispatch_async(url_session_manager_processing_queue(), ^{
               
               strongify(self);
              
               NSError *parsingError;
               
               NSString *contentType = [[response allHeaderFields] valueForKey:@"Content-Type"];
               
               if (self.responseParser != nil && contentType != nil) {
                   
                   contentType = [[contentType componentsSeparatedByString:@";"] firstObject];
                   
                   if ([self.responseParser.contentTypes containsObject:contentType] == NO) {
                       
                       NSString *responseText = @"";
                       
                       if ([contentType isEqualToString:@"text/html"]) {
                           
                           NSStringEncoding encoding = NSUTF8StringEncoding;
                           
                           if ([response.allHeaderFields[@"content-type"] containsString:@"charset="]) {
                               
                               NSString *contentTypeHeader = response.allHeaderFields[@"contentType"];
                               
                               NSUInteger index = [contentTypeHeader rangeOfString:@"charset="].location + 8;
                               
                               NSString *encodingType = [[contentTypeHeader substringFromIndex:index] lowercaseString];
                               
                               if ([encodingType isEqualToString:@"utf-16"] || [encodingType isEqualToString:@"utf16"]) {
                                   encoding = NSUTF16StringEncoding;
                               }
                               else if ([encodingType isEqualToString:@"utf-32"] || [encodingType isEqualToString:@"utf32"]) {
                                   encoding = NSUTF32StringEncoding;
                               }
                               
                           }
                           
                           responseText = [[NSString alloc] initWithData:data encoding:encoding];
                           
                       }
                       
                       parsingError = [NSError errorWithDomain:DZErrorDomain code:503 userInfo:@{
                           NSLocalizedDescriptionKey: @"The content was not of the expected types.",
                           NSLocalizedFailureErrorKey: responseText
                       }];
                       
                       if (errorBlock) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               errorBlock(parsingError, response, task);
                           });
                       }
                       
                       return;
                       
                   }
                   
               }
               
               id responseObject = self.responseParser != nil ? [self.responseParser parseResponse:data :response error:&parsingError] : data;
               
               if (parsingError) {
                   
                   if (errorBlock) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           errorBlock(parsingError, response, task);
                       });
                   }
                   
                   return;
                   
               }
            
               if(response.statusCode > self.maximumSuccessStatusCode) {
                    
                    // Treat this as an error.
                    NSDictionary *userInfo = @{DZErrorData     : data ?: [NSData data],
                                               DZErrorResponse : responseObject ?: @{},
                                               DZErrorTask     : task};
                    
                    NSError * statusCodeError = [NSError errorWithDomain:NSCocoaErrorDomain code:response.statusCode userInfo:userInfo];
                    
                    if (errorBlock) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorBlock(statusCodeError, response, task);
                        });
                        
                    }
                    
                    return;
                    
                }
                
                if(response.statusCode == 200 && !responseObject)
                {
                    // our request succeeded but returned no data. Treat valid.
                    if (successBlock) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            successBlock(responseObject ?: data, response, task);
                        });
                        
                    }
                    return;
                }
                
                if (parsingError) {
                    if (errorBlock) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorBlock(parsingError, response, task);
                        });
                    }
                    return;
                }
                
                if (successBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successBlock(responseObject, response, task);
                    });
                }
               
            });
            
            return;
            
        }
        else {
            // data was nil
            // treat at a 304 status
            NSDictionary *userInfo = @{DZErrorData     : data ?: [NSData data],
                                       DZErrorResponse : @{},
                                       DZErrorTask     : task};
            
            NSError * statusCodeError = [NSError errorWithDomain:NSCocoaErrorDomain code:304 userInfo:userInfo];
            
            if (errorBlock) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    errorBlock(statusCodeError, response, task);
                });
                
            }
        }
        
    }
    else {
        
        if (successBlock) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                successBlock(nil, (NSHTTPURLResponse *)[task response], task);
                
            });
            
        }
        
    }
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    
    if (completionHandler) {
        completionHandler(disposition);
    }
    
}

- (void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(nonnull NSURL *)location {
    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)[task response];
    
    if (response.statusCode != 304) {
        
        NSError *error = nil;
        
        NSData *data = [NSData dataWithContentsOfURL:location options:NSDataReadingMappedIfSafe error:&error];
        
        if (error != nil) {
            // errored
            NSLog(@"Error: loading data for background task from location: %@", location);
        }
        else {
            
            @synchronized (self) {
                self.backgroundResponseData[@(task.taskIdentifier)] = data.mutableCopy;
            }
            
        }
        
    }
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data {
    
    NSMutableData *responseData;
    
    @synchronized (self) {
        responseData = self.backgroundResponseData[@(dataTask.taskIdentifier)];
    }
    
    if (responseData == nil) {
        responseData = [NSMutableData dataWithData:data];
        
        @synchronized (self) {
            self.backgroundResponseData[@(dataTask.taskIdentifier)] = responseData;
        }
        
    }
    else {
        [responseData appendData:data];
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    
    NSData *data;
    
    @synchronized (self) {
        data = [self.backgroundResponseData objectForKey:@(task.taskIdentifier)];
    }
    
    [self handleResponseFor:task responseData:data error:error];
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
    if (self.backgroundCompletionHandler) {
        
#ifdef DEBUG
        NSLog(@"Calling background completion handler");
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            self.backgroundCompletionHandler();
            
        });
        
    }
    
}

#pragma mark - MSG Forwarding

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    
    if ([(id)self.delegate respondsToSelector:[anInvocation selector]])
    {
        [anInvocation invokeWithTarget:self.delegate];
    }
    else
    {
        [super forwardInvocation:anInvocation];
    }
    
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    
    if (self.delegate == self) {
        return [super respondsToSelector:aSelector];
    }
    
    return [(id)self.delegate respondsToSelector:aSelector] || [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature)
    {
        signature = [(id)self.delegate methodSignatureForSelector:selector];
    }
    return signature;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    NSURLSessionConfiguration *configuration = [decoder decodeObjectOfClass:[NSURLSessionConfiguration class] forKey:@"sessionConfiguration"];
    
    self = [self initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.session.configuration forKey:@"sessionConfiguration"];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithSessionConfiguration:self.session.configuration];
}

@end
