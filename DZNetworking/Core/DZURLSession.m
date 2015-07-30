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
    
    return [self performRequestWithURI:URI method:@"GET" params:params];
    
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
       
        if(query)
        {
            NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
            
            id queryString = OMGFormURLEncode(query);
            if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
            
            NSMutableURLRequest *req = [OMGHTTPURLRQ POST:url :params];
            
            if(self.requestModifier)
            {
                req = [self.requestModifier(req) mutableCopy];
            }
            
            resolve([self requestWithReq:req]);
        }
        else
        {
            resolve([self performRequestWithURI:URI method:@"POST" params:params]);
        }
        
    }]
    .then(^(DZPromise *promise) {
    
        return promise;
    
    });
    
}

- (DZPromise *)PUT:(NSString *)URI
        parameters:(NSDictionary *)params
{
    
    return [self performRequestWithURI:URI method:@"PUT" params:params];
    
}

- (DZPromise *)PUT:(NSString *)URI
       queryParams:(NSDictionary *)query
        parameters:(NSDictionary *)params
{
    
    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        if(query)
        {
            NSString *url = [NSURL URLWithString:URI relativeToURL:self.baseURL].absoluteString;
            
            id queryString = OMGFormURLEncode(query);
            if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
            
            NSMutableURLRequest *req = [OMGHTTPURLRQ PUT:url :params];
            
            if(self.requestModifier)
            {
                req = [self.requestModifier(req) mutableCopy];
            }
            
            resolve([self requestWithReq:req.copy]);
        }
        else
        {
            resolve([self performRequestWithURI:URI method:@"PUT" params:params]);
        }
        
    }]
    .then(^(DZPromise *promise) {
        
        return promise;
        
    });
    
}

- (DZPromise *)PATCH:(NSString *)URI
          parameters:(NSDictionary *)params
{
    
    return [self performRequestWithURI:URI method:@"PATCH" params:params];
    
}

- (DZPromise *)DELETE:(NSString *)URI
           parameters:(NSDictionary *)params
{
    
    return [self performRequestWithURI:URI method:@"DELETE" params:params];
    
}

- (DZPromise *)HEAD:(NSString *)URI
         parameters:(NSDictionary *)params
{
    
    return [self performRequestWithURI:URI method:@"HEAD" params:params];
    
}

- (DZPromise *)OPTIONS:(NSString *)URI
            parameters:(NSDictionary *)params
{
    
    return [self performRequestWithURI:URI method:@"OPTIONS" params:params];
    
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
        
        if([method isEqualToString:@"GET"])
        {
            mutableRequest = [OMGHTTPURLRQ GET:url :params];
        }
        else if([method isEqualToString:@"POST"])
        {
            mutableRequest = [OMGHTTPURLRQ POST:url :params];
        }
        else if([method isEqualToString:@"PUT"])
        {
            mutableRequest = [OMGHTTPURLRQ PUT:url :params];
        }
        else if([method isEqualToString:@"DELETE"])
        {
            mutableRequest = [OMGHTTPURLRQ DELETE:url :params];
        }
        else
        {
            mutableRequest = [OMGHTTPURLRQ GET:url :params];
            mutableRequest.HTTPMethod = method;
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
        
        resolve(request);
        
    }];
    
}

- (DZPromise *)performRequestWithURI:(NSString *)URI
                              method:(NSString *)method
                              params:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:method params:params]
    .then(^(NSURLRequest *request) {
        
        return [self requestWithReq:request];
        
    });
    
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
                
                NSDictionary *userInfo = @{DZErrorData : data ?: [NSData data],
                                           DZErrorResponse : responseObject ?: @{},
                                           DZErrorTask : task};
                
                NSError *error = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
                
                resolve(error);
                return;
                
            }
            
            if(res.statusCode == 200 && !responseObject)
            {
                // our request succeeded but returned no data. Treat valid.
                DZResponse *obj = [[DZResponse alloc] initWithData:responseObject :res :task];
                
                resolve(obj);
                return;
            }
            
            if(jsonError)
            {
                resolve(jsonError);
                return;
            }
            
            DZResponse *obj = [[DZResponse alloc] initWithData:responseObject :res :task];
            
            resolve(obj);
            
        }];
        
        [task resume];
        
    }];

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

@end
