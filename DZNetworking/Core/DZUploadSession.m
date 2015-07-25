//
//  DZUploadSession.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/23/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZUploadSession.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface DZMultipartFormData : OMGMultipartFormData {
@public
    NSMutableData *body;
}

@end

@implementation DZMultipartFormData

@end

@interface DZUploadSession () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation DZUploadSession

+ (instancetype)shared
{
    
    static dispatch_once_t onceToken;
    static DZUploadSession *dzsession = nil;
    dispatch_once(&onceToken, ^{
        
        dzsession = [[DZUploadSession alloc] init];
        
    });
    
    return dzsession;
    
}

- (instancetype)init
{
    
    if(self = [super init])
    {
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 1;
        
        _session = [NSURLSession sessionWithConfiguration:defaultConfig];
        
    }
    
    return self;
    
}

- (DZPromise *)UPLOAD:(NSString *)path
            fieldName:(NSString *)fieldName
                  URL:(NSString *)URL
           parameters:(NSDictionary *)params
{
    
    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        
        NSString *contentType = [[self class] mimeTypeForFileAtPath:path];
        
        DZMultipartFormData *processed = [[DZMultipartFormData alloc] init];
        
        NSData *data = [[NSData alloc] initWithContentsOfFile:path];
        
        [processed addFile:data parameterName:fieldName filename:[path lastPathComponent] contentType:contentType];
        
        if(params)
        {
            [processed addParameters:params];
        }
        
        NSError *error = nil;
        
        NSMutableURLRequest *request = [OMGHTTPURLRQ POST:URL :processed error:&error];
        
        if(error)
        {
            resolve(error);
            return;
        }
        
        __block NSURLSessionUploadTask *task = [self.session uploadTaskWithRequest:request.copy fromData:nil completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if(error)
            {
                resolve(error);
                return;
            }
            
            NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
            
            NSError *jsonError;
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            
            if(res.statusCode > 399)
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

- (DZPromise *)UPLOAD:(NSData *)data
                 name:(NSString *)name
            fieldName:(NSString *)fieldName
                  URL:(NSString *)URL
           parameters:(NSDictionary *)params
{
    
    return [DZPromise promiseWithResolverBlock:^(PMKResolver resolve) {
       
        //create a temporary file from the data.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
        
        if([fileManager fileExistsAtPath:path])
        {
            
            NSError *error = nil;
            
            if(![fileManager removeItemAtPath:path error:&error])
            {
                resolve(error);
                return;
            }
            
        }
        
        if(![data writeToFile:path atomically:YES])
        {
            
            NSError *error = [NSError errorWithDomain:DZErrorDomain code:2000 userInfo:nil];
            resolve(error);
            return;
            
        }
        
        resolve(path);
        
    }]
    .then(^(NSString *path) {
        
        return [self UPLOAD:path fieldName:fieldName URL:URL parameters:params];
        
    });
    
}

#pragma mark - Helpers

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path
{
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        return nil;
    }
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    
    if (!mimeType) {
        return @"application/octet-stream";
    }
    
    return (__bridge NSString *)(mimeType);
    
}


@end
