//
//  PurgingDiskCache.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 07/12/17.
//  Copyright © 2017 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef weakify
#define weakify(var) __weak typeof(var) AHKWeak_##var = var;
#endif

#ifndef strongify
#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = AHKWeak_##var; \
_Pragma("clang diagnostic pop")
#endif

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

#ifndef DZAPPKIT
#import <UIKit/UIKit.h>
#endif

@interface PurgingDiskCache : NSCache

#ifndef DZAPPKIT

- (void)setObject:(UIImage * _Nonnull)obj data:(NSData * _Nullable)data forKey:(NSString * _Nonnull)key;

- (void)setObject:(UIImage * _Nonnull)obj data:(NSData * _Nullable)data forKey:(NSString * _Nonnull)key cost:(NSUInteger)cost;

- (void)objectforKey:(NSString * _Nonnull)key callback:(void(^_Nullable)(UIImage * _Nullable image))cb;

- (void)removeObjectForKey:(NSString * _Nonnull)key;

- (void)removeAllObjectsFromDisk;

#endif

@end
