//
//  DZActivityIndicatorManager.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/8/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZActivityIndicatorManager.h"

#if TARGET_OS_IOS == 1

#import <UIKit/UIApplication.h>

#endif

@interface DZActivityIndicatorManager ()

@property (atomic, assign) NSInteger activityCount;

@end

@implementation DZActivityIndicatorManager

+ (DZActivityIndicatorManager *)shared
{
    
    static dispatch_once_t onceToken;
    static DZActivityIndicatorManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[DZActivityIndicatorManager alloc] init];
    });
    
    return instance;
    
}

- (instancetype)init
{
    
    if(self = [super init])
    {
        _activityCount = 0;
    }
    
    return self;
    
}

- (void)decrementCount
{
    
    self.activityCount = MAX(self.activityCount-1, 0);
    
    [self updateIndicatorVisibility];
    
}

- (void)incrementCount
{
    
    self.activityCount += 1;
    
    [self updateIndicatorVisibility];
    
}

- (BOOL)isShowingActivityIndicator
{
    return self.activityCount > 0;
}

- (void)updateIndicatorVisibility
{
    
#if TARGET_OS_IOS == 1
    
    if (![NSThread isMainThread]) {
        return [self performSelectorOnMainThread:@selector(updateIndicatorVisibility) withObject:nil waitUntilDone:NO];
    }
    
    BOOL show = [self isShowingActivityIndicator];
    
    BOOL isShowing = [[UIApplication sharedApplication] isNetworkActivityIndicatorVisible];
    
    if(show == isShowing) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:show];
        
    });
#endif
}

@end
