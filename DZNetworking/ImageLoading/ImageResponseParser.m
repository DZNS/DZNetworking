//
//  ImageResponseParser.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ImageResponseParser.h"
#import "UIImage+GIF.h"
#import "WebPImageSerialization.h"

@implementation ImageResponseParser

#if TARGET_OS_IOS == 1

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error
{
    
    NSString *contentType = [[response allHeaderFields] valueForKey:@"Content-Type"];
    UIImage *image = nil;
    
    if ([contentType isEqualToString:@"image/gif"]) {
        image = [UIImage animatedImageWithAnimatedGIFData:responseData];
    }
    
    else if ([contentType isEqualToString:@"image/webp"]) {
        image = [UIImage imageWithWebPData:responseData];
    }
    
    else {
        image = [UIImage imageWithData:responseData];
    }
    
    return image;
}

#endif

- (NSSet *)contentTypes
{
    return [NSSet setWithArray:@[@"image/jpg", @"image/jpeg", @"image/png", @"image/gif", @"image/webp"]];
}

@end
