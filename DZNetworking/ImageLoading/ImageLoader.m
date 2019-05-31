//
//  ImageLoader.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ImageLoader.h"
#import "ImageResponseParser.h"

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


ImageLoader *SharedImageLoader;

@interface DZURLSession ()

- (NSURLRequest *)requestWithURI:(NSString *)URI
                          method:(NSString *)method
                          params:(NSDictionary *)params;

@end

@interface ImageLoader ()

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
        
        self.ioQueue = dispatch_queue_create("com.dezinezync.imageloader.io", DISPATCH_QUEUE_CONCURRENT);
        
#ifndef DZAPPKIT
      [NSNotificationCenter.defaultCenter addObserver:self.cache selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc
{
#ifndef DZAPPKIT
    [NSNotificationCenter.defaultCenter removeObserver:self];
#endif
}

#pragma mark -

- (void)clearMemoryCache {
    
    [self.cache removeAllObjects];
    
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
    
    NSURLRequest *req = [self requestWithURI:[(NSURL *)url absoluteString] method:@"GET" params:nil];
    return [self il_performRequest:req success:successCB error:errorCB];
}

- (NSURLSessionTask *)il_performRequest:(NSURLRequest *)request success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    weakify(self);
    
    __block id cachedObj = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self.cache objectforKey:request.URL.absoluteString callback:^(UIImage * _Nullable image) {
        
        cachedObj = image;
        
        UNLOCK(semaphore);
        
    }];
    
    LOCK(semaphore);
    
    if (cachedObj != nil) {
        if (successCB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(cachedObj, nil, nil);
            });
        }
        
        return nil;
    }
    
    __block NSURLSessionDataTask *task = nil;
    
    url_session_manager_create_task_safely(^{
       
        task = [(NSURLSession *)[self valueForKeyPath:@"session"] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
#ifndef DZAPPKIT
            // we simply decrement it. No harm, since we ensure the value never drops below 0.
            [[DZActivityIndicatorManager shared] decrementCount];
#endif
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            NSInteger statusCode = res.statusCode;
            
            if (statusCode > 399 && !error) {
                error = [[NSError alloc] initWithDomain:@"ImageLoader" code:statusCode userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"An error occurred when loading %@", request.URL]}];
            }
            
            if(error)
            {
                if (errorCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorCB(error, res, task);
                    });
                }
                return;
            }
            
            dispatch_async(url_session_manager_processing_queue(), ^{
            
                strongify(self);
                
                NSError *parsingError;
                UIImage *responseObject = [self.responseParser parseResponse:data :res error:&parsingError];
                
                if (responseObject) {
                    [self.cache setObject:responseObject data:data forKey:request.URL.absoluteString];
                }
                
                if(res.statusCode > self.maximumSuccessStatusCode)
                {
                    
                    // Treat this as an error.
                    
                    NSDictionary *userInfo = @{DZErrorData : data ?: [NSData data],
                                               DZErrorResponse : responseObject ?: @{},
                                               DZErrorTask : task};
                    
                    NSError * statusCodeError = [NSError errorWithDomain:DZErrorDomain code:res.statusCode userInfo:userInfo];
                    
                    if (errorCB) {
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            errorCB(statusCodeError, res, task);
                        });
                        
                    }
                    
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
    
    if (task != nil) {
        [task resume];
    }
#ifndef DZAPPKIT
    if(self.useActivityManager)
        [[DZActivityIndicatorManager shared] incrementCount];
#endif
    return task;
}

#pragma mark -

- (PurgingDiskCache *)cache {
    if (_cache == nil) {
        _cache = [[PurgingDiskCache alloc] init];
    }
    
    return _cache;
}

@end
