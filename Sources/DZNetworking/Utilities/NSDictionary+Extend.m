//
//  NSDictionary+Extend.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 10/2/15.
//  Copyright © 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import "NSDictionary+Extend.h"

@implementation NSDictionary (Extend)

- (NSDictionary *_Nonnull)dz_extend:(NSDictionary *_Nonnull)dict
{
    
    NSMutableDictionary *selfCopy = [self mutableCopy];
    
    [selfCopy addEntriesFromDictionary:dict];
    
    return [selfCopy copy];
    
}

@end
