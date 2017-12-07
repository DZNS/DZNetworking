//
//  DZS3CredentialsManager.m
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

#import "DZS3CredentialsManager.h"
#import <CommonCrypto/CommonCrypto.h>

NSString *const kDZACLPrivate = @"private";
NSString *const kDZACLPublic = @"public";

NSString *const kDZEncryptionAES256 = @"AES256";

@interface NSData (MD5)

- (NSString *)md5;

@end

@implementation NSData (MD5)

- (NSString *)md5
{
    
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
    
}

- (NSString *)base64
{
    return [self base64EncodedStringWithOptions:0];
}

@end

@interface NSString (DZ)

- (NSData *)hmacSha1:(NSString *)secret;

@end

@implementation NSString (DZ)

- (NSData *)hmacSha1:(NSString *)secret
{
    
    const char *cKey = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [self cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    return HMAC;
    
}

@end

@interface DZS3CredentialsManager ()

@property (nonatomic, copy) NSString *public, *secret;

@end

@implementation DZS3CredentialsManager

- (instancetype)initWithKey:(NSString *)key secret:(NSString *)secret
{
    
    NSAssert(key, @"A public access key was not provided");
    NSAssert(secret, @"A secret access key was not provided");

    if(self = [super init])
    {
        _public = key;
        _secret = secret;
    }
    
    return self;
    
}

- (NSString *)authorizationWithMethod:(NSString *)method
                               bucket:(NSString *)bucket
                                 path:(NSString *)path
                              content:(NSData *)data
                                  ACL:(NSString *)ACL
                           encryption:(NSString *)encryption
                          contentType:(NSString *)contentType
                              expires:(NSString *)expires
{
    
    NSAssert(method, @"The method type was not provided");
    
    // for the following two requests, these are not required.
    if(!([method isEqualToString:@"PUT"] || ![method isEqualToString:@"POST"]))
    {
        data        = nil;
        ACL         = nil;
        encryption  = nil;
        contentType = nil;
    }
    else if ([method isEqualToString:@"PUT"])
    {
        NSAssert(data, @"The data to be uploaded was not provided.");
    }
    
    NSAssert(bucket, @"The bucket name was not provided");
    NSAssert(path, @"The resource path was not provided");
    NSAssert(expires, @"The expiry time was not provided");
    
    NSMutableString *stringToSign = [NSMutableString string];
    
    [stringToSign appendFormat:@"%@\n", [method uppercaseString]];
    [stringToSign appendFormat:@"%@\n", @""]; //content-md5 goes in here, but AWS doesn't seem to care and throws an error.
    [stringToSign appendString:@"\n"];
    [stringToSign appendFormat:@"%@\n", expires];
    
    if(ACL)
    {
        [stringToSign appendFormat:@"x-amz-acl:%@\n", ACL];
    }
    
    if(encryption)
    {
        [stringToSign appendFormat:@"x-amz-server-side-encryption:%@\n", encryption];
    }
    
    [stringToSign appendFormat:@"/%@%@", bucket, path];
    NSLog(@"String to Sign: %@", stringToSign);
    NSString *signature = [[stringToSign hmacSha1:self.secret] base64];
    
    return [NSString stringWithFormat:@"AWS %@:%@", self.public, signature];
    
}

@end
