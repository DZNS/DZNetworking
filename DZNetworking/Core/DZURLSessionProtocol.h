//
//  DZURLSessionProtocol.h
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/22/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#ifndef DZNetworking_DZURLSessionProtocol_h
#define DZNetworking_DZURLSessionProtocol_h

@protocol DZURLSessionProtocol <NSObject>

@optional
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler;

@end

#endif
