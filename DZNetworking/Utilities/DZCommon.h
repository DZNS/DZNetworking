//
//  DZCommon.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/23/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <DZNetworking/DZURLSessionProtocol.h>
#import <DZNetworking/DZResponse.h>
#import <DZNetworking/NSString+URLExtended.h>

#ifdef DEBUG
    #define DZLog(fmt,...) {\
        NSLog((@"(%s - Line: %d) " fmt),__func__,__LINE__,##__VA_ARGS__);\
    }
#else
    #define DZLog(fmt,...) {}
#endif

extern NSString *const DZErrorDomain;
extern NSString *const DZErrorData;
extern NSString *const DZErrorResponse;
extern NSString *const DZErrorTask;
extern NSInteger const DZUnusableRequestError;

typedef NSMutableURLRequest *(^requestModifierBlock)(NSMutableURLRequest *request);
typedef NSURLRequest *(^redirectModifierBlock)(NSURLSessionTask *task, NSURLRequest *request, NSHTTPURLResponse *redirectResponse);

typedef void (^successBlock)(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task);
typedef void (^progressBlock)(double completed, NSProgress *progress); // 0.0 to 1.0
typedef void (^errorBlock)(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task);
