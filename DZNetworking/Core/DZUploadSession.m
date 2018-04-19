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
#import <DZNetworking/DZURLSession.h>
#if TARGET_OS_IOS == 1
#import <MobileCoreServices/MobileCoreServices.h>
#elif TARGET_OS_WATCH
#import <MobileCoreServices/MobileCoreServices.h>
#elif TARGET_OS_UNIX == 1
#import <CoreServices/CoreServices.h>
#endif

#import <objc/runtime.h>

#import "OMGHTTPURLRQ.h"

static void *kTaskProgressBlock;
static char *kTaskProgressContext;

@interface DZUploadSession () <DZURLSessionProtocol>

@property (nonatomic, strong) DZURLSession *session;

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
    
    if(self = [super init]) {
        _session = [[DZURLSession alloc] init];
    }
    
    return self;
    
}

- (NSURLSessionTask *)UPLOAD:(NSString *)path
                   fieldName:(NSString *)fieldName
                         URL:(NSString *)URL
                  parameters:(NSDictionary *)params
                     success:(successBlock)successCB
                    progress:(progressBlock)progressCB
                       error:(errorBlock)errorCB
{
    
    NSString *contentType = [[self class] mimeTypeForFileAtPath:path];
    
    OMGMultipartFormData *processed = [[OMGMultipartFormData alloc] init];
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    [processed addFile:data parameterName:fieldName filename:[path lastPathComponent] contentType:contentType];
    
    if(params)
    {
        [processed addParameters:params];
    }
    
    NSMutableURLRequest *request = [OMGHTTPURLRQ POST:URL :processed error:nil];
    
    NSURLSessionTask *task = [self.session POST:request success:successCB error:errorCB];
    
    if (@available(iOS 11, *)) {
        if (progressCB) {
            objc_setAssociatedObject(task.progress, &kTaskProgressBlock, progressCB, OBJC_ASSOCIATION_COPY);
            [task.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:&kTaskProgressContext];
        }
    }
    
    return task;
    
}

- (NSURLSessionTask *)UPLOAD:(NSData *)data name:(NSString *)name fieldName:(NSString *)fieldName URL:(NSString *)URL parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB
{
    return [self UPLOAD:data name:name fieldName:fieldName URL:URL parameters:params success:successCB progress:nil error:errorCB];
}

- (NSURLSessionTask *)UPLOAD:(NSData *)data
                        name:(NSString *)name
                   fieldName:(NSString *)fieldName
                         URL:(NSString *)URL
                  parameters:(NSDictionary *)params
                     success:(successBlock)successCB
                    progress:(progressBlock)progressCB
                       error:(errorBlock)errorCB
{
    
    //create a temporary file from the data.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    
    if([fileManager fileExistsAtPath:path])
    {
        
        NSError *error = nil;
        
        if(![fileManager removeItemAtPath:path error:&error])
        {
           if (errorCB)
               errorCB(error, nil, nil);
            return nil;
        }
        
    }
    
    if(![data writeToFile:path atomically:YES])
    {
        
        NSError *error = [NSError errorWithDomain:DZErrorDomain code:2000 userInfo:nil];
        if (errorCB)
            errorCB(error, nil, nil);
        return nil;
        
    }
    
    
    return [self UPLOAD:path fieldName:fieldName URL:URL parameters:params success:successCB progress:progressCB error:errorCB];
    
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

#pragma mark - <KVO>

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(fractionCompleted))] && context == &kTaskProgressContext) {
        NSProgress *progress = object;
        
        progressBlock block = objc_getAssociatedObject(object, &kTaskProgressBlock);
        
        if (block) {
            double completed = [progress fractionCompleted];
            
            block(completed, progress);
        }
    }
}

@end
