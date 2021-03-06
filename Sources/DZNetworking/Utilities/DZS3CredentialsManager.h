//
//  DZS3CredentialsManager.h
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

#import <Foundation/Foundation.h>

extern NSString *const kDZACLPrivate;
extern NSString *const kDZACLPublic;

extern NSString *const kDZEncryptionAES256;

@interface DZS3CredentialsManager : NSObject

- (instancetype)initWithKey:(NSString *)key secret:(NSString *)secret;

- (NSString *)authorizationWithMethod:(NSString *)method
                               bucket:(NSString *)bucket
                                 path:(NSString *)path
                              content:(NSData *)data
                                  ACL:(NSString *)ACL
                           encryption:(NSString *)encryption
                          contentType:(NSString *)contentType
                              expires:(NSString *)expires;

@end
