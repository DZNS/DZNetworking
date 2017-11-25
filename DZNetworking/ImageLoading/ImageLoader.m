//
//  ImageLoader.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ImageLoader.h"
#import "ImageResponseParser.h"

ImageLoader *SharedImageLoader;

@interface DZURLSession ()

- (NSURLRequest *)requestWithURI:(NSString *)URI
                          method:(NSString *)method
                          params:(NSDictionary *)params;

@end

@interface ImageLoader ()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation ImageLoader

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SharedImageLoader = [ImageLoader new];
    });
}

- (instancetype)init
{
    if (self = [super init]) {
        self.responseParser = [ImageResponseParser new];
        self.cache = [[NSCache alloc] init];
        self.cache.name = @"imageCache";
    }
    
    return self;
}

- (NSURLSessionTask *)downloadImageForURL:(id)url success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (url && [url isKindOfClass:NSString.class])
        url = [NSURL URLWithString:url];
    
    if (![url isKindOfClass:NSURL.class] || !url) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"ImageLoader" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Please provide a valid URL for downloading."}], nil, nil);
        }
        
        return nil;
    }
    
    NSURLRequest *req = [self requestWithURI:[(NSURL *)url absoluteString] method:@"GET" params:@{}];
    return [self il_performRequest:req success:successCB error:errorCB];
}

- (NSURLSessionTask *)il_performRequest:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    UIImage *cached = [self.cache objectForKey:request.URL.absoluteString];
    
    if (cached) {
        if (successCB)
            successCB(cached, nil, nil);
        return nil;
    }
    
    __weak typeof(self) weakSelf = self;
    
    __block NSURLSessionDataTask *task = [(NSURLSession *)[self valueForKeyPath:@"session"] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
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
        
        typeof(self) strongSelf = weakSelf;
        
        NSError *parsingError;
        UIImage *responseObject = [strongSelf.responseParser parseResponse:data :res error:&parsingError];
        
        if (responseObject) {
            [strongSelf.cache setObject:responseObject forKey:request.URL.absoluteString];
        }
        
        if(res.statusCode > strongSelf.maximumSuccessStatusCode)
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    successCB(responseObject ?: data, res, task);
                });
            return;
        }
        
        if (parsingError) {
            if (errorCB)
                errorCB(parsingError, res, task);
            return;
        }
        
        if (successCB)
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(responseObject, res, task);
            });
        return;
        
    }];
    
    [task resume];
#ifndef DZAPPKIT
    if(self.useActivityManager)
        [[DZActivityIndicatorManager shared] incrementCount];
#endif
    
    return task;
}

@end