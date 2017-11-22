//
//  UIImage+ImageLoading.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UIImageView+ImageLoading.h"
#import <objc/runtime.h>

static char DOWNLOAD_TASK;

@implementation UIImageView (ImageLoading)

- (void)il_setImageWithURL:(id)url
{
    if (self.task)
        [self.task cancel];
    
    __weak typeof(self) weakSelf = self;
    
    if ([url rangeOfString:@"?"].location != NSNotFound) {
        url = [url substringToIndex:[url rangeOfString:@"?"].location];
    }
    
    self.task = [SharedImageLoader downloadImageForURL:url success:^(UIImage *image, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.image = image;
        [strongSelf setNeedsDisplay];
        
        CGRect frame = strongSelf.frame;
        CGFloat height = (image.size.height / image.size.width) * frame.size.width;
        
        frame.size.height = height;
        
        if (strongSelf.constraints.count) {
            BOOL found = NO;
            for (NSLayoutConstraint *constraint in strongSelf.constraints) {
                if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                    found = YES;
                    constraint.constant = height;
                    
                    [self layoutIfNeeded];
                }
            }
            
            if (found)
                return;
        }
        else if ([strongSelf.superview isKindOfClass:UIStackView.class]) {
            // inside a stackview but no height constraint
            [strongSelf.heightAnchor constraintEqualToConstant:height].active = YES;
            return;
        }
        
        strongSelf.frame = frame;
        
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
    }
}

#pragma mark - Runtime

-(void)setTask:(NSURLSessionTask *)task
{
    objc_setAssociatedObject(self, &DOWNLOAD_TASK, task, OBJC_ASSOCIATION_ASSIGN);
}

-(NSURLSessionTask *)task
{
    return (NSURLSessionTask *)objc_getAssociatedObject(self, &DOWNLOAD_TASK);
}


@end
