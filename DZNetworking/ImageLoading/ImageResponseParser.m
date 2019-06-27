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

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error {
    
    NSString *contentType = [[response allHeaderFields] valueForKey:@"Content-Type"];
    __block UIImage *image = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = self.ioQueue ?: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^{
        if ([contentType isEqualToString:@"image/gif"]) {
            image = [UIImage animatedImageWithAnimatedGIFData:responseData];
        }
        
        else if ([contentType isEqualToString:@"image/webp"]) {
            image = [UIImage imageWithWebPData:responseData];
        }
        
        else {
            image = [UIImage imageWithData:responseData];
        }
        
        dispatch_semaphore_signal(semaphore);
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return image;
}

#endif

- (NSSet *)contentTypes {
    return [NSSet setWithArray:@[@"image/jpg", @"image/jpeg", @"image/png", @"image/gif", @"image/webp"]];
}

@end
