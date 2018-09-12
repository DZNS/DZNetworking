//
//  DZJSONResponseParser.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/9/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZJSONResponseParser.h"

@implementation DZJSONResponseParser

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error
{
    
    __autoreleasing id responseObject = nil;
    
    if(responseData && responseData.length)
    {
        // ensure & enforce utf-8 encoding.
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        responseData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        
        responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:error];
    
    }
    
    return responseObject;
    
}

- (NSSet *)contentTypes
{
    return [NSSet setWithObjects:@"application/json", @"text/javascript", @"text/json", nil];
}

@end
