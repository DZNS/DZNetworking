//
//  NSString+Coders.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 10/2/15.
//  Copyright © 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Coders)

- (NSString * _Nonnull)encodeURI;
- (NSString * _Nonnull)decodeURI;

- (NSString * _Nonnull)md5 NS_DEPRECATED_IPHONE(11, 13.5);

@end
