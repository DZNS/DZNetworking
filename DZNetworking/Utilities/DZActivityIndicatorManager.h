//
//  DZActivityIndicatorManager.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/8/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZActivityIndicatorManager : NSObject

+ (instancetype)shared;

- (BOOL)isShowingActivityIndicator;

- (void)incrementCount;
- (void)decrementCount;

@end
