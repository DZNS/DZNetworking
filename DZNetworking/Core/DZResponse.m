//
//  DZResponse.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/28/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZResponse.h"

@implementation DZResponse

- (instancetype)initWithData:(id)responseObject :(NSHTTPURLResponse *)response :(NSURLSessionTask *)task
{
    
    if(self = [super init])
    {
        _responseObject = responseObject;
        _response = response;
        _task = task;
    }
    
    return self;
    
}

@end
