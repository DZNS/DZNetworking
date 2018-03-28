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
#ifndef DZAPPKIT
#import <DZNetworking/DZActivityIndicatorManager.h>
#endif
@interface DZURLSession() <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;

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

- (instancetype)init
{
    
    if(self = [super init])
    {
        
        _maximumSuccessStatusCode = 399;
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 5;
        
        NSURLCache *cache = [[NSURLCache alloc] initWithMemoryCapacity:10*1024*1024 // 10 MegaBytes
                                                          diskCapacity:100*1024*1024 // 100 MegaBytes
                                                              diskPath:nil];
        
        defaultConfig.URLCache = cache;
        
        _session = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:[NSOperationQueue currentQueue]];
        
        _useActivityManager = YES;
        
    }
    
    return self;
    
}

#pragma mark - HTTP Methods

- (void)GET:(NSString *)URI parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"GET" params:params success:successCB error:errorCB];
    
}

- (void)POST:(NSString *)URI
         parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self POST:URI queryParams:nil parameters:params success:successCB error:errorCB];
    
}

- (void)POST:(NSString *)URI
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

- (void)PUT:(NSString *)URI
        parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"PUT" params:params success:successCB error:errorCB];
    
}

- (void)PUT:(NSString *)URI
       queryParams:(NSDictionary *)query
        parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
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

- (void)PATCH:(NSString *)URI
          parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"PATCH" params:params success:successCB error:errorCB];
    
}

- (void)DELETE:(NSString *)URI
           parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"DELETE" params:params success:successCB error:errorCB];
    
}

- (void)HEAD:(NSString *)URI
         parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"HEAD" params:params success:successCB error:errorCB];
    
}

- (void)OPTIONS:(NSString *)URI
            parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    return [self performRequestWithURI:URI method:@"OPTIONS" params:params success:successCB error:errorCB];
    
}

#pragma mark - 

- (void)GET:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"GET" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)PUT:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"PUT" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)POST:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"POST" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)PATCH:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"PATCH" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)DELETE:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"DELETE" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)OPTIONS:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    req = [self ensureHTTPMethod:@"OPTIONS" onRequest:req];
    
    return [self requestWithReq:req success:successCB error:errorCB];
    
}

- (void)HEAD:(NSURLRequest *)req success:(successBlock)successCB error:(errorBlock)errorCB
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

- (void)performRequestWithURI:(NSString *)URI
                              method:(NSString *)method
                              params:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSURLRequest *req = [self requestWithURI:URI method:method params:params];
    
    [self requestWithReq:req success:successCB error:errorCB];
}

- (void)requestWithReq:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB
{
    __block NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
#ifndef DZAPPKIT
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
        
        NSError *parsingError;
        id responseObject = [self.responseParser parseResponse:data :res error:&parsingError];
        
        if(res.statusCode > self.maximumSuccessStatusCode)
        {
            
            // Treat this as an error.
            
            NSDictionary *userInfo = @{DZErrorData : data ?: [NSData data],
                                       DZErrorResponse : responseObject ?: @{},
                                       DZErrorTask : task};
            
            error = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
            
            if (errorCB)
                errorCB(error, res, task);
            return;
            
        }
        
        if(res.statusCode == 200 && !responseObject)
        {
            // our request succeeded but returned no data. Treat valid.
            if (successCB)
                successCB(responseObject ?: data, res, task);
            return;
        }
        
        if (parsingError) {
            if (errorCB)
                errorCB(parsingError, res, task);
            return;
        }
        
        if (successCB)
            successCB(responseObject, res, task);
        return;
        
    }];
    
    [task resume];
#ifndef DZAPPKIT
    if(self.useActivityManager) [[DZActivityIndicatorManager shared] incrementCount];
#endif
}

#pragma mark - NSURLSessionDelegate

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
    NSURLRequest *newRequest = nil;
    
    if (self.redirectModifier) {
        newRequest = self.redirectModifier(request, redirectResponse);
        if (redirectResponse) {
            newRequest = nil;
        }
    }
    else {
        newRequest = request;
        if (redirectResponse) {
            newRequest = nil;
        }
    }
    
    completionHandler(newRequest);
}

@end
