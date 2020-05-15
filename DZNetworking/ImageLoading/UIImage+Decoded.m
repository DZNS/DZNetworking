//
//  UIImage+Decoded.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 15/05/20.
//  Copyright © 2020 Dezine Zync Studios LLP. All rights reserved.
//

#import "UIImage+Decoded.h"
#import <CoreGraphics/CGImage.h>

@implementation UIImage (Decoded)

- (UIImage *)decodedImage {
    
    CGImageRef imageRef = self.CGImage;
    
    if (!imageRef) {
        return self;
    }
    
    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpaceRef, kCGImageAlphaPremultipliedFirst);
    
    CGColorSpaceRelease(colorSpaceRef);
    
    if (!context) {
        
        CGImageRelease(imageRef);
        
        return self;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), imageRef);
    
    CGImageRef decoded = CGBitmapContextCreateImage(context);
    
    CGImageRelease(imageRef);
    
    CGContextRelease(context);
    
    if (!decoded) {
        return self;
    }
    
    UIImage *decodedImage = [UIImage imageWithCGImage:decoded];
    
    return decodedImage;
    
}

@end
