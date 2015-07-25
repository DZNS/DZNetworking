//
//  DZUploadSession.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/23/15.
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

#import "DZUploadSession.h"
#import <MobileCoreServices/MobileCoreServices.h>

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
        
        OMGMultipartFormData *processed = [[OMGMultipartFormData alloc] init];
        
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
    
    NSString *type = (__bridge NSString *)(mimeType);
    CFRelease(mimeType);
    
    return type;
    
}


@end
