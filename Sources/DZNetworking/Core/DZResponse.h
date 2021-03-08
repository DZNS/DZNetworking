//
//  DZResponse.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/28/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZResponse : NSObject

@property (nonatomic, copy, readonly) id responseObject;
@property (nonatomic, copy, readonly) NSHTTPURLResponse *response;
@property (nonatomic, copy, readonly) NSURLSessionTask *task;

- (instancetype)initWithData:(id)responseObject :(NSHTTPURLResponse *)response :(NSURLSessionTask *)task;

@end
