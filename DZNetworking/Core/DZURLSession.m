//
//  DZURLSession.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZURLSession.h"

NSString *const DZErrorDomain = @"com.dz.error.domain";
NSString *const DZErrorData = @"com.dz.error.data";
NSString *const DZErrorResponse = @"com.dz.error.response";
NSString *const DZErrorTask = @"com.dz.error.task";

@interface DZURLSession()

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
        
        _session = [NSURLSession sessionWithConfiguration:defaultConfig];
        
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
    
    return [self requestWithURI:URI method:@"POST" params:params];
    
}

- (DZPromise *)PUT:(NSString *)URI
        parameters:(NSDictionary *)params
{
    
    return [self requestWithURI:URI method:@"PUT" params:params];
    
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

- (DZPromise *)requestWithURI:(NSString *)URI
                        method:(NSString *)method
                        params:(NSDictionary *)params
{
    
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        NSURL *URL = [NSURL URLWithString:URI relativeToURL:self.baseURL];
        
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:URL];
        mutableRequest.HTTPMethod = method;
        
        NSURLRequest *request = [self formattedRequest:mutableRequest withParameters:params];
        
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           
            if(error)
            {
                resolve(error);
                return;
            }
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            NSError *jsonError;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            
            if(jsonError)
            {
                resolve(jsonError);
                return;
            }
            
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
            
            resolve(PMKManifold(responseObject, res, task));
            
        }];
        
        [task resume];
        
    }];
    
}

#pragma mark - Helpers

- (NSURLRequest *)formattedRequest:(NSURLRequest *)request
                    withParameters:(NSDictionary *)parameters
{
    NSParameterAssert(request);
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    // Update the HTTP Headers for the request if they exist.
    if(self.HTTPHeaders && self.HTTPHeaders.count)
    {
        
        for(NSString *key in self.HTTPHeaders)
        {
            
            // If a value for the HTTP Header is set, skip the default.
            if([mutableRequest valueForHTTPHeaderField:key]) continue;
            
            [mutableRequest setValue:[self.HTTPHeaders valueForKey:key] forHTTPHeaderField:key];
            
        }
        
    }
    
    // Lets work out the Parameters.
    if(parameters && parameters.count)
    {
        
        NSString *serialized = [self serializedQueryStringFromParams:parameters];
        
        NSString *method = mutableRequest.HTTPMethod;
        
        // We set it in the URL as query params for the following methods.
        if([method isEqualToString:@"GET"] ||
           [method isEqualToString:@"DELETE"] ||
           [method isEqualToString:@"HEAD"] ||
           [method isEqualToString:@"OPTIONS"])
        {
            
            NSString *url;
            
            // If we have existing query, append the params.
            if([mutableRequest.URL.absoluteString containsString:@"?"])
            {
                url = [NSString stringWithFormat:@"%@&%@", mutableRequest.URL.absoluteString, serialized];
            }
            // Add the params normally.
            else
            {
                url = [NSString stringWithFormat:@"%@?%@", mutableRequest.URL.absoluteString, serialized];
            }
            
            NSURL *URL = [NSURL URLWithString:url];
            
            mutableRequest.URL = URL;
            
        }
        
        // These need the params in the HTTPBody.
        // If you need query params, include them in the URL directly.
        else if ([method isEqualToString:@"PUT"] ||
                 [method isEqualToString:@"POST"] ||
                 [method isEqualToString:@"PATCH"])
        {
            mutableRequest.HTTPBody = [serialized dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        // Undefined behavior. If you run into this, please open an issue on https://github.com/DZNS/DZNetworking/
        else
        {
            DZLog(@"Undefined behavior for setting request parameters.");
        }
        
    }
    
    return mutableRequest.copy;
}

- (NSString *)serializedQueryStringFromParams:(NSDictionary *)params
{
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:params.count];
    
    for(NSString *key in params)
    {
        NSString *item = [@[key, [params objectForKey:key]] componentsJoinedByString:@"="];
        [array addObject:item];
    }
    
    return [array componentsJoinedByString:@"&"];
    
}

@end
