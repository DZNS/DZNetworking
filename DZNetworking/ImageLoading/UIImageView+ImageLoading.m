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

static char DOWNLOAD_TASK;

@implementation UIImageView (ImageLoading)

- (void)il_setImageWithURL:(id)url
{
    if (self.task)
        [self il_cancelImageLoading];
    
    weakify(self);
    
//    if ([url rangeOfString:@"?"].location != NSNotFound) {
//        url = [url substringToIndex:[url rangeOfString:@"?"].location];
//    }
    
    self.task = [SharedImageLoader downloadImageForURL:url success:^(UIImage *image, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.image = image;
        [self setNeedsDisplay];
        
        CGRect frame = self.frame;
        CGFloat height = (image.size.height / image.size.width) * frame.size.width;
        
        frame.size.height = height;
        
        if (self.constraints.count) {
            BOOL found = NO;
            for (NSLayoutConstraint *constraint in self.constraints) {
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
        else if ([self.superview isKindOfClass:UIStackView.class]) {
            // inside a stackview but no height constraint
            weakify(self);
            asyncMain(^{
                strongify(self);
                [self.heightAnchor constraintEqualToConstant:height].active = YES;
            })
            return;
        }
        
        weakify(self);
        asyncMain(^{
            strongify(self);
            self.frame = frame;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
#ifdef DEBUG
        NSLog(@"%@", error);
#endif
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

-(NSURLSessionTask *)task
{
    return (NSURLSessionTask *)objc_getAssociatedObject(self, &DOWNLOAD_TASK);
}


@end
