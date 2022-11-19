//
//  NSString+URLExtended.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/30/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "NSString+URLExtended.h"

@implementation NSString (URLExtended)

+ (NSString *)URIWithFormat:(NSString *)format, ...
{
    
    va_list args;
    va_start(args, format);
    NSString *contents = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    return contents;
    
}

@end

@implementation NSURL (URLExtended)

+ (NSURL *)URLWithFormat:(NSString *)format, ...
{
    
    va_list args;
    va_start(args, format);
    NSString *contents = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    NSURL *url = [NSURL URLWithString:contents];
    
    return url;
    
}

@end
