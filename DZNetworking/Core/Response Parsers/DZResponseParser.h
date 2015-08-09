//
//  DZResponseParser.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 8/9/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Subclasses of the DZResponseParser class are responsible for correctly parsing the response from network requests. This class by itself does nothing. You should subclass it and implement the necessary methods and then assign it to your DZURLSession object.
 */
@interface DZResponseParser : NSObject

/**
 *  The DZURLSession object passes the response data and response to this method. This method must be implemented by subclasses to provide specific handling of response parsing.
 *
 *  @param responseData the responseData, if any, sent over the wire.
 *  @param response     the response object which contains helpful information like response headers, status code, etc.
 *
 *  @return The processed response object. What you return from this method will depend on your subclass.
 */
- (id)parseResponse:(NSData *)responseData :(NSHTTPURLResponse *)response error:(NSError **)error;

/**
 *  A set of acceptable content-types. This is checked before parsing the information. If the content-type does not match, you can possibly return back the NSData itself, or perhaps, try parsing it and handle any exceptions on the way.
 *
 *  @return A set of acceptable content-types.
 */
- (NSSet *)contentTypes;

/**
 *  This is a convinience method to check the response contentType. Subclasses need not implement this method. However, you're free to override it to provide very specific cases.
 *
 *  @return YES if the contentType matches, NO otherwise.
 */
- (BOOL)isExpectedContentType:(NSHTTPURLResponse *)response;

@end
