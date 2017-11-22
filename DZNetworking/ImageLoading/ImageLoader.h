//
//  ImageLoader.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <DZNetworking/DZNetworking.h>

@class ImageLoader;

extern ImageLoader * _Nonnull SharedImageLoader;

@interface ImageLoader : DZURLSession

- (NSURLSessionTask * _Nullable)downloadImageForURL:(id _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

@end
