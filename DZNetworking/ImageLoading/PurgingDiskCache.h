//
//  PurgingDiskCache.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 07/12/17.
//  Copyright © 2017 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef DZAPPKIT
#import <UIKit/UIKit.h>
#endif

@interface PurgingDiskCache : NSCache

#ifndef DZAPPKIT

- (void)setObject:(UIImage * _Nonnull)obj data:(NSData * _Nullable)data forKey:(NSString * _Nonnull)key;

- (void)setObject:(UIImage * _Nonnull)obj data:(NSData * _Nullable)data forKey:(NSString * _Nonnull)key cost:(NSUInteger)cost;

- (void)objectforKey:(NSString * _Nonnull)key callback:(void(^_Nullable)(UIImage * _Nullable image))cb;

- (void)removeObjectForKey:(NSString * _Nonnull)key;

#endif

@end
