//
//  DZJSONResponseParser.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/9/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZJSONResponseParser.h"

@implementation DZJSONResponseParser

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error {
    
    __autoreleasing id responseObject = nil;
    
    if(responseData && responseData.length) {
        responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:error];
    
    }
    
    return responseObject;
    
}

- (NSSet *)contentTypes {
    return [NSSet setWithObjects:@"application/json", @"text/javascript", @"text/json", nil];
}

@end
