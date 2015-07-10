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
        
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
           
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

@end
