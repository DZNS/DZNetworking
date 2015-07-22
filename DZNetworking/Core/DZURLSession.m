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

NSString *const DZErrorDomain = @"com.dz.error.domain";
NSString *const DZErrorData = @"com.dz.error.data";
NSString *const DZErrorResponse = @"com.dz.error.response";
NSString *const DZErrorTask = @"com.dz.error.task";
NSInteger const DZUnusableRequestError = 2100;

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
        
    }
    
    return self;
    
}

#pragma mark - HTTP Methods

- (DZPromise *)GET:(NSString *)URI
         parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"GET" params:params];
    
}

- (DZPromise *)POST:(NSString *)URI
         parameters:(NSDictionary *)params
{
    
    return [self POST:URI queryParams:nil parameters:params];
    
}

- (DZPromise *)POST:(NSString *)URI
        queryParams:(NSDictionary *)query
         parameters:(NSDictionary *)params
{

    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
       
        NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
        
        id queryString = OMGFormURLEncode(params);
        if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
        
        NSError *error = nil;
        NSMutableURLRequest *req = [OMGHTTPURLRQ POST:url :params error:&error];
        
        if(error)
        {
            resolve(error);
            return;
        }
        
        resolve([self requestWithReq:req.copy]);
        
    }]
    .then(^(DZPromise *promise) {
    
        return promise;
    
    });
    
}

- (DZPromise *)PUT:(NSString *)URI
        parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"PUT" params:params];
    
}

- (DZPromise *)PUT:(NSString *)URI
       queryParams:(NSDictionary *)query
        parameters:(NSDictionary *)params
{
    
    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
        
        id queryString = OMGFormURLEncode(params);
        if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
        
        NSError *error = nil;
        NSMutableURLRequest *req = [OMGHTTPURLRQ PUT:url :params error:&error];
        
        if(error)
        {
            resolve(error);
            return;
        }
        
        resolve([self requestWithReq:req.copy]);
        
    }]
    .then(^(DZPromise *promise) {
        
        return promise;
        
    });
    
}

- (DZPromise *)PATCH:(NSString *)URI
          parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"PATCH" params:params];
    
}

- (DZPromise *)DELETE:(NSString *)URI
           parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"DELETE" params:params];
    
}

- (DZPromise *)HEAD:(NSString *)URI
         parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"HEAD" params:params];
    
}

- (DZPromise *)OPTIONS:(NSString *)URI
            parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"OPTIONS" params:params];
    
}

#pragma mark - 

- (DZPromise *)GET:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"GET" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)PUT:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"PUT" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)POST:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"POST" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)PATCH:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"PATCH" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)DELETE:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"DELETE" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)OPTIONS:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"OPTIONS" onRequest:req];
    
    return [self requestWithReq:req];
    
}

- (DZPromise *)HEAD:(NSURLRequest *)req
{
    
    req = [self ensureHTTPMethod:@"HEAD" onRequest:req];
    
    return [self requestWithReq:req];
    
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

- (DZPromise *)requestWithURI:(NSString *)URI
                        method:(NSString *)method
                        params:(NSDictionary *)params
{
    
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
        
        NSMutableURLRequest *mutableRequest;
        
        NSError *error;
        
        if([method isEqualToString:@"GET"])
        {
            mutableRequest = [OMGHTTPURLRQ GET:url :params error:&error];
        }
        else if([method isEqualToString:@"POST"])
        {
            mutableRequest = [OMGHTTPURLRQ POST:url :params error:&error];
        }
        else if([method isEqualToString:@"PUT"])
        {
            mutableRequest = [OMGHTTPURLRQ PUT:url :params error:&error];
        }
        else if([method isEqualToString:@"DELETE"])
        {
            mutableRequest = [OMGHTTPURLRQ DELETE:url :params error:&error];
        }
        else
        {
            mutableRequest = [OMGHTTPURLRQ GET:url :params error:&error];
            mutableRequest.HTTPMethod = method;
        }
        
        if(error)
        {
            resolve(error);
            return;
        }
        
        NSURLRequest *request = mutableRequest.copy;
        
        if(self.requestModifier)
        {
            
            request = self.requestModifier(request);
            
            if(!request)
            {
                
                NSError *modifierError = [[NSError alloc] initWithDomain:DZErrorDomain code:DZUnusableRequestError userInfo:nil];
                
                resolve(modifierError);
                
                return;
                
            }
            
        }
        
        __block NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           
            if(error)
            {
                resolve(error);
                return;
            }
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            NSError *jsonError;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            
            if(res.statusCode > self.maximumSuccessStatusCode)
            {
                
                // Treat this as an error.
                
                NSDictionary *userInfo = @{DZErrorData : data,
                                           DZErrorTask : task};
                
                NSError *error = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
                
                resolve(error);
                return;
                
            }
            
            if(jsonError)
            {
                resolve(jsonError);
                return;
            }
            
            resolve(PMKManifold(responseObject, res, task));
            
        }];
        
        [task resume];
        
    }];
    
}

- (DZPromise *)requestWithReq:(NSURLRequest *)request
{
    
    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        __block NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if(error)
            {
                resolve(error);
                return;
            }
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            NSError *jsonError;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            
            if(res.statusCode > self.maximumSuccessStatusCode)
            {
                
                // Treat this as an error.
                
                NSDictionary *userInfo = @{DZErrorData : data,
                                           DZErrorResponse : responseObject,
                                           DZErrorTask : task};
                
                NSError *error = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
                
                resolve(error);
                return;
                
            }
            
            if(jsonError)
            {
                resolve(jsonError);
                return;
            }
            
            resolve(PMKManifold(responseObject, res, task));
            
        }];
        
        [task resume];
        
    }];

}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    
    [self callDelegate:@selector(URLSession:didReceiveChallenge:completionHandler:) arg1:session arg2:challenge arg3:completionHandler];
    
}

#pragma mark - Helpers

- (void)callDelegate:(SEL)aSelector
{
    
    if(self.delegate && [self.delegate respondsToSelector:aSelector])
    {
        
        NSMethodSignature * ms = [self methodSignatureForSelector:aSelector];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:ms];
        [inv setTarget:self.delegate];
        [inv setSelector:aSelector];
        [inv invoke];
        
    }
    
}

- (id)callDelegate:(SEL)aSelector arg1:(id)param1 arg2:(id)param2 arg3:(id)param3
{
    
    if(self.delegate && [self.delegate respondsToSelector:aSelector])
    {
     
        NSMethodSignature * ms = [self methodSignatureForSelector:aSelector];
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:ms];
        [inv setTarget:self.delegate];
        [inv setSelector:aSelector];
        [inv setArgument:&param1 atIndex:2];
        [inv setArgument:&param2 atIndex:3];
        [inv setArgument:&param3 atIndex:3];
        [inv invoke];
        id returnObject = nil;
        [inv getReturnValue:&returnObject];
        
        return returnObject;
        
    }
    
    return nil;
    
}

@end
