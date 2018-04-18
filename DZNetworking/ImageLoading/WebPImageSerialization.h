//
//  WebPImageSerialization.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 18/04/18.
//  Copyright © 2018 Dezine Zync Studios LLP. All rights reserved.
//  Base Code adapted from: https://github.com/shmidt/WebP-UIImage
//

#import <UIKit/UIKit.h>

@interface UIImage (WebP)

- (NSData * _Nullable)dataWebPWithQuality:(CGFloat)quality;//quality = 0..100
+ (UIImage * _Nullable)imageWithWebPAtPath:(NSString * _Nonnull)filePath;

+ (UIImage * _Nullable)imageWithWebPData:(NSData * _Nonnull)imgData;

@property (nonatomic, readonly) NSData *dataWebPLossless;

- (BOOL)writeWebPToDocumentsWithFileName:(NSString * _Nonnull)filename quality:(CGFloat)quality;
- (BOOL)writeWebPLosslessToDocumentsWithFileName:(NSString * _Nonnull)filename;

@end
