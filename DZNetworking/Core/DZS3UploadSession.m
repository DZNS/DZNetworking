//
//  DZS3UploadSession.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/25/15.
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

#import "DZS3UploadSession.h"

@interface DZS3UploadSession () <DZURLSessionProtocol>

@property (nonatomic, strong) DZURLSession *session;

@end

@implementation DZS3UploadSession

+ (DZS3UploadSession *)shared
{
    
    static dispatch_once_t onceToken;
    static DZS3UploadSession *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[DZS3UploadSession alloc] init];
    });
    
    return instance;
    
}

- (instancetype)init
{
 
    if(self = [super init])
    {
        _session = [[DZURLSession alloc] init];
        _session.delegate = self;
    }
    
    return self;
    
}

- (void)UPLOAD:(NSString *)filePath
            publicKey:(NSString *)key
               bucket:(NSString *)bucket
                 path:(NSString *)path
                  ACL:(NSString *)ACL
           encryption:(NSString *)encryption
              expires:(NSTimeInterval)expiry
              success:(successBlock)successCB
                error:(errorBlock)errorCB
{
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    NSString *contentType = [DZUploadSession mimeTypeForFileAtPath:filePath];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"];
    
    NSDate *date = [NSDate date];
    NSString *expires = [formatter stringFromDate:date];
    
    if(!self.credentialsManager)
    {
        NSError *error = [NSError errorWithDomain:@"DZError" code:0 userInfo:@{}];
        if (errorCB)
            errorCB(error, nil, nil);
        return;
    }
    
    NSString *authorizationHeader = [self.credentialsManager authorizationWithMethod:@"PUT"
                                                                              bucket:bucket
                                                                                path:path
                                                                             content:data
                                                                                 ACL:ACL
                                                                          encryption:encryption
                                                                         contentType:contentType
                                                                             expires:expires];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/%@%@", bucket, path]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    [request setValue:ACL forHTTPHeaderField:@"X-Amz-Acl"];
    [request setValue:encryption forHTTPHeaderField:@"X-amz-server-side-encryption"];
    [request setValue:@"s3.amazonaws.com" forHTTPHeaderField:@"Host"];
    [request setValue:expires forHTTPHeaderField:@"Date"];
    [request setValue:[@([data length]) stringValue] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    [request setHTTPMethod:@"PUT"];
    
    [self.session PUT:request.copy success:successCB error:errorCB];
    
}

#pragma mark - <DZURLSessionProtocol>

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    
}

@end
