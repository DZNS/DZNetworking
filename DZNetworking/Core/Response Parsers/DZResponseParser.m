//
//  DZResponseParser.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/9/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "DZResponseParser.h"

@implementation DZResponseParser

- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError *__autoreleasing *)error
{
    
    NSAssert(YES, @"Subclasses must implement this method and not call super.");
    
    return nil;
    
}

- (NSSet *)contentTypes
{
    
    NSAssert(YES, @"Subclasses must implement this method and not call super.");
    
    return nil;
    
}

- (BOOL)isExpectedContentType:(NSHTTPURLResponse *)response
{
    
    NSString *type = [[response allHeaderFields] valueForKey:@"Content-Type"];
    
    if(!type)
    {
        return NO;
    }
    
    return [[self contentTypes] containsObject:type];
    
}

@end
