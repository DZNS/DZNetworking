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

typedef NSURLRequest *(^requestModifierBlock)(NSURLRequest *request);
typedef NSURLRequest *(^redirectModifierBlock)(NSURLRequest *request, NSHTTPURLResponse *redirectResponse);

typedef void (^successBlock)(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task);
typedef void (^errorBlock)(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task);
