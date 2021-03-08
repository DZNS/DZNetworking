//
//  NSString+URLExtended.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/30/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLExtended)

+ (NSString *)URIWithFormat:(NSString *)format, ...;

@end

@interface NSURL (URLExtended)

+ (NSURL *)URLWithFormat:(NSString *)format, ...;

@end
