//
//  DZCommon.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/23/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DZNetworking/DZURLSessionProtocol.h>
#import <PromiseKit/PromiseKit.h>
#import <OMGHTTPURLRQ/OMGHTTPURLRQ.h>

#ifdef DEBUG

#define DZLog(fmt,...) {\
NSLog((@"(%s - Line: %d) " fmt),__func__,__LINE__,##__VA_ARGS__);\
}

#else

#define DZLog(fmt,...) {}

#endif

#define DZPromise AnyPromise

extern NSString *const DZErrorDomain;
extern NSString *const DZErrorData;
extern NSString *const DZErrorResponse;
extern NSString *const DZErrorTask;
extern NSInteger const DZUnusableRequestError;