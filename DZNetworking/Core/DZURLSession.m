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
#import <DZNetworking/DZActivityIndicatorManager.h>
#endif

#import "OMGHTTPURLRQ.h"

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
static dispatch_queue_t url_session_manager_creation_queue() {
    static dispatch_queue_t dz_url_session_manager_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dz_url_session_manager_creation_queue = dispatch_queue_create("com.dezinezync.networking.session.manager.creation", DISPATCH_QUEUE_SERIAL);
    });
    
    return dz_url_session_manager_creation_queue;
}

// The following lines of code are taken from AFNetworking/AFURLSessionManager.m
static void url_session_manager_create_task_safely(dispatch_block_t _Nonnull block) {
    if (block != NULL) {
        if (NSFoundationVersionNumber < NSFoundationVersionNumber_With_Fixed_5871104061079552_bug) {
            // Fix of bug
            // Open Radar:http://openradar.appspot.com/radar?id=5871104061079552 (status: Fixed in iOS8)
            // Issue about:https://github.com/AFNetworking/AFNetworking/issues/2093
            dispatch_sync(url_session_manager_creation_queue(), block);
        } else {
            block();
        }
    }
}

// The following lines of code are taken from AFNetworking/AFURLSessionManager.m
static dispatch_queue_t url_session_manager_processing_queue() {
    static dispatch_queue_t dz_url_session_manager_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dz_url_session_manager_processing_queue = dispatch_queue_create("com.dezinezync.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return dz_url_session_manager_processing_queue;
}

@interface DZURLSession() <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;

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
        _operationQueue = [[NSOperationQueue alloc] init];
        
        _useActivityManager = YES;
    }
    
    return self;
}

- (instancetype)init
{
    
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    defaultConfig.HTTPMaximumConnectionsPerHost = 5;
    
    NSInteger const RAMCapacity = 10*1024*1024; // 10 MegaBytes
    NSInteger const diskCapacity = 100*1024*1024; // 100 MegaBytes
    
    NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:RAMCapacity
                                                      diskCapacity:diskCapacity
                                                          diskPath:nil];
    
    defaultConfig.URLCache = cache;
    defaultConfig.timeoutIntervalForRequest = 15;
    
    self = [self initWithSessionConfiguration:defaultConfig];
    
    return self;
    
}

#pragma mark - Session Getter

- (NSURLSession *)session {
    if (_session == nil) { @autoreleasepool {
        _session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];
    } }
    
    return _session;
}

#pragma mark - HTTP Methods

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
            req = [self.requestModifier(req) mutableCopy];
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
        if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
        
        NSMutableURLRequest *req = [OMGHTTPURLRQ PUT:url :params error:nil];
        
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
                       params:(NSDictionary *)params
{
    
    NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
    
    NSMutableURLRequest *mutableRequest;
    
    if([method isEqualToString:@"GET"])
    {
        mutableRequest = [OMGHTTPURLRQ GET:url :params error:nil];
    }
    else if([method isEqualToString:@"POST"])
    {
        mutableRequest = [OMGHTTPURLRQ POST:url :params error:nil];
    }
    else if([method isEqualToString:@"PUT"])
    {
        mutableRequest = [OMGHTTPURLRQ PUT:url :params error:nil];
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
    
    NSURLRequest *request = mutableRequest.copy;
    
    if(self.requestModifier)
    {
        
        request = self.requestModifier(request);
        
        if(!request)
        {
            
            NSError *modifierError = [[NSError alloc] initWithDomain:DZErrorDomain code:DZUnusableRequestError userInfo:nil];
            
            @throw modifierError;
            
        }
        
    }
    
    /*
     * sanitize the URL request.
     * 1. the URL shouldn't have a ? if there are no searchParams
     */
    
    if (!params || !params.allKeys.count) {
        NSString *uri = request.URL.absoluteString;
        if ([[uri substringFromIndex:uri.length-1] isEqualToString:@"?"]) {
            uri = [uri substringToIndex:uri.length-1];
            
            mutableRequest = request.mutableCopy;
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

- (NSURLSessionTask *)requestWithReq:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB
{
    __block NSURLSessionDataTask *task = nil;
    
    weakify(self);
    
    url_session_manager_create_task_safely(^{
        
        strongify(self);
        
        task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
#if TARGET_OS_IOS == 1
            // we simply decrement it. No harm, since we ensure the value never drops below 0.
            [[DZActivityIndicatorManager shared] decrementCount];
#endif
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            if(error)
            {
                if (errorCB)
                    errorCB(error, res, task);
                return;
            }
            
            weakify(self);
            
            dispatch_async(url_session_manager_processing_queue(), ^{
                
                strongify(self);
               
                NSError *parsingError;
                id responseObject = [self.responseParser parseResponse:data :res error:&parsingError];
                
                if(res.statusCode > self.maximumSuccessStatusCode)
                {
                    
                    // Treat this as an error.
                    
                    NSDictionary *userInfo = @{DZErrorData     : data ?: [NSData data],
                                               DZErrorResponse : responseObject ?: @{},
                                               DZErrorTask     : task};
                    
                    NSError * statusCodeError = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
                    
                    if (errorCB) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorCB(statusCodeError, res, task);
                        });
                        
                    }
                    
                    return;
                    
                }
                
                if(res.statusCode == 200 && !responseObject)
                {
                    // our request succeeded but returned no data. Treat valid.
                    if (successCB) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            successCB(responseObject ?: data, res, task);
                        });
                        
                    }
                    return;
                }
                
                if (parsingError) {
                    if (errorCB) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorCB(parsingError, res, task);
                        });
                    }
                    return;
                }
                
                if (successCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCB(responseObject, res, task);
                    });
                }
                return;
                
            });
            
        }];
    });
    
    if (task) {
        [task resume];
    }
#if TARGET_OS_IOS == 1
    if(self.useActivityManager) {
        [[DZActivityIndicatorManager shared] incrementCount];
    }
#endif
    
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
    
    if ([session isEqual:self.session]) {
        [self invalidateSessionCancelingTasks:NO];
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(URLSession:didReceiveChallenge:completionHandler:)])
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
