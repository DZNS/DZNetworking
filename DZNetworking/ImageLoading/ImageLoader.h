//
//  ImageLoader.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <DZNetworking/DZNetworking.h>
#import <DZNetworking/UIImage+GIF.h>

#import <DZNetworking/PurgingDiskCache.h>

#ifndef runOnMainQueueWithoutDeadlockingExport
#define runOnMainQueueWithoutDeadlockingExport 1
FOUNDATION_EXPORT void runOnMainQueueWithoutDeadlocking(void (^ _Nonnull block)(void));
#endif

@class ImageLoader;

extern ImageLoader * _Nonnull SharedImageLoader;

@interface ImageLoader : DZURLSession

@property (nonatomic, strong) PurgingDiskCache * _Nonnull cache;

@property (nonatomic, strong) dispatch_queue_t _Nonnull ioQueue;

- (NSURLSessionTask * _Nullable)downloadImageForURL:(id _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

@end
