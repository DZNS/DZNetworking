//
//  ImageResponseParser.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "ImageResponseParser.h"

@implementation ImageResponseParser

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error
{
    UIImage *image = [UIImage imageWithData:responseData];
    return image;
}

- (NSSet *)contentTypes
{
    return [NSSet setWithArray:@[@"image/jpg", @"image/jpeg", @"image/png"]];
}

@end
