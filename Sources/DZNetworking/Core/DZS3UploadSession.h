//
//  DZS3UploadSession.h
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

#import "DZURLSession.h"
#import "DZUploadSession.h"
#import "../Utilities/DZS3CredentialsManager.h"

@interface DZS3UploadSession : NSObject

@property (nonatomic, strong) DZS3CredentialsManager *credentialsManager;

+ (DZS3UploadSession *)shared;

- (void)UPLOAD:(NSString *)filePath
     publicKey:(NSString *)key
        bucket:(NSString *)bucket
          path:(NSString *)path
           ACL:(NSString *)ACL
    encryption:(NSString *)encryption
       expires:(NSTimeInterval)expiry
       success:(successBlock)successCB
         error:(errorBlock)errorCB;

@end
