//
//  UIImage+ImageLoading.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageLoader.h"

@interface UIImageView (ImageLoading)

- (void)il_setImageWithURL:(id _Nonnull)url;

- (void)il_setImageWithURL:(id _Nonnull)url success:(void (^_Nullable)(UIImage * _Nonnull image, NSURL * _Nonnull URL))success error:(void (^_Nullable)(NSError * _Nonnull error))error;


- (void)il_cancelImageLoading;

@end
