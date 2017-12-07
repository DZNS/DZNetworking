//
//  NSString+Coders.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 10/2/15.
//  Copyright © 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "NSString+Coders.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (Coders)

- (NSString *_Nonnull)encodeURI
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"]];                                                                  
}

- (NSString *_Nonnull)decodeURI
{
    return [self stringByRemovingPercentEncoding];
}

- (NSString *)md5
{
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
