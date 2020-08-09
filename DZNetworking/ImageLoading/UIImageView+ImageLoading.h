//
//  UIImage+ImageLoading.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZNetworking/ImageLoader.h>
#import <objc/runtime.h>

@class ImageLoader;

@interface UIImageView (ImageLoading)

/**
 * After the image is loaded from the network and set on the view, frames or constraints are automatically updated.
 * @default: YES
 */
@property (nonatomic, assign) BOOL autoUpdateFrameOrConstraints;

- (void)il_setImageWithURL:(id _Nonnull)url;

- (void)il_setImageWithURL:(id _Nonnull)url
                   success:(void (^_Nullable)(UIImage * _Nonnull image, NSURL * _Nonnull URL))success
                     error:(void (^_Nullable)(NSError * _Nonnull error))error;

- (void)il_setImageWithURL:(id _Nonnull)url
                    mutate:(UIImage * _Nonnull (^ _Nullable)(UIImage * _Nonnull image))mutate
                   success:(void (^_Nullable)(UIImage * _Nonnull image, NSURL * _Nonnull URL))success
                     error:(void (^_Nullable)(NSError * _Nonnull error))error;

- (void)il_setImageWithURL:(id _Nonnull)url
                    mutate:(UIImage * _Nonnull(^ _Nullable)(UIImage * _Nonnull))mutate
                   success:(void (^ _Nullable)(UIImage * _Nonnull, NSURL * _Nonnull))success
                     error:(void (^ _Nullable)(NSError * _Nonnull))errorCB
               imageLoader:(ImageLoader * _Nonnull)imageLoader;

- (void)il_cancelImageLoading;

@end
