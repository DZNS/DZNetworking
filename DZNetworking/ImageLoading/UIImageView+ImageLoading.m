//
//  UIImage+ImageLoading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UIImageView+ImageLoading.h"
#import <objc/runtime.h>

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

#ifndef asyncMain
#define asyncMain(block) {\
    if([NSThread isMainThread]) {\
        block();\
    }\
    else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }\
};
#endif

#ifndef syncMain
#define syncMain(block) {\
    if ([NSThread isMainThread]) {\
        block();\
    }\
    else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }\
};
#endif

static char DOWNLOAD_TASK;
static char AUTO_UPDATING_FRAME;

@implementation UIImageView (ImageLoading)

- (void)il_setImageWithURL:(id)url
{
    [self il_setImageWithURL:url success:nil error:nil];
}

- (void)il_setImageWithURL:(id)url success:(void (^ _Nullable)(UIImage * _Nonnull, NSURL * _Nonnull))success error:(void (^ _Nullable)(NSError * _Nonnull))errorCB
{
    if (self.task)
        [self il_cancelImageLoading];
    
    weakify(self);
    
    self.task = [SharedImageLoader downloadImageForURL:url success:^(UIImage *image, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        asyncMain(^{
            self.image = image;
            [self setNeedsDisplay];
        });
        
        if (!self.autoUpdateFrameOrConstraints) {
            if (success) {
                success(image, url);
            }
            return;
        }
        
        __block CGRect frame;
        __block CGSize imageSize;
        __block NSArray <NSLayoutConstraint *> *constraints;
        
        if (NSThread.isMainThread) {
            frame = self.frame;
            imageSize = image.size;
            constraints = self.constraints;
        }
        else
            dispatch_sync(dispatch_get_main_queue(), ^{
                frame = self.frame;
                imageSize = image.size;
                constraints = self.constraints;
            });
        
        CGFloat height = (imageSize.height / imageSize.width) * frame.size.width;
        
        frame.size.height = height;
        
        __block BOOL exitEarly = NO;
        
        if (constraints.count) {
            BOOL found = NO;
            
            for (NSLayoutConstraint *constraint in constraints) {
                if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                    found = YES;
                    
                    weakify(self);
                    
                    asyncMain(^{
                        constraint.constant = height;
                        strongify(self);
                        [self layoutIfNeeded];
                    });
                    
                }
            }
            
            if (found)
                return;
        }
        else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([self.superview isKindOfClass:UIStackView.class]) {
                    // inside a stackview but no height constraint
                    weakify(self);
                    asyncMain(^{
                        strongify(self);
                        [self.heightAnchor constraintEqualToConstant:height].active = YES;
                    });
                    
                    exitEarly = YES;
                }
            });
        }
        
        if (exitEarly) {
            if (success) {
                success(image, url);
            }
            return;
        }
        
        weakify(self);
        asyncMain(^{
            strongify(self);
            self.frame = frame;
        });
        
        if (success) {
            success(image, url);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
        
        if (errorCB) {
            errorCB(error);
        }
    }];
}

- (void)il_cancelImageLoading
{
    if (self.task) {
        [self.task cancel];
        self.task = nil;
    }
}

#pragma mark - Runtime

-(void)setTask:(NSURLSessionTask *)task
{
    objc_setAssociatedObject(self, &DOWNLOAD_TASK, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)setAutoUpdateFrameOrConstraints:(BOOL)autoUpdateFrameOrConstraints
{
    objc_setAssociatedObject(self, &AUTO_UPDATING_FRAME, @(autoUpdateFrameOrConstraints), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSURLSessionTask *)task
{
    return (NSURLSessionTask *)objc_getAssociatedObject(self, &DOWNLOAD_TASK);
}

-(BOOL)autoUpdateFrameOrConstraints
{
    return (BOOL)[objc_getAssociatedObject(self, &AUTO_UPDATING_FRAME) boolValue];
}

@end
