//
//  DZUploadSession.h
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

#import <Foundation/Foundation.h>
#import <DZNetworking/DZCommon.h>

@interface DZUploadSession : NSObject

+ (DZUploadSession *)shared;

#pragma mark - Uploads

/**
 *  Upload a file at a given path.
 *
 *  @param filePath the path to the file to be uploaded, preferrably from the NSTemporaryDirectory().
 *  @param fieldName    the field name of the POST form. Defaults to "file".
 *  @param URL          the URL.
 *  @param params   Parameters for the request. These will be included in the HTTP Body along with the file's data.
 *
 *  @return DZPromise.
 */
- (void)UPLOAD:(NSString *)filePath
            fieldName:(NSString *)fieldName
                  URL:(NSString *)URL
           parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

/**
 *  Upload a file with the provided data and mime-type.
 *
 *  @param data         the NSData representation of the file.
 *  @prarm name         the name of the file.
 *  @param fieldName    the field name of the POST form. Defaults to "file".
 *  @param URL          the URL.
 *  @param params       Parameters for the request. These will be included in the HTTP Body along with the file's data.
 *
 *  @return DZPromise.
 */
- (void)UPLOAD:(NSData *)data
                 name:(NSString *)name
            fieldName:(NSString *)fieldName
                  URL:(NSString *)URL
           parameters:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB;

#pragma mark - Internal

+ (NSString *)mimeTypeForFileAtPath:(NSString *)path;

@end
