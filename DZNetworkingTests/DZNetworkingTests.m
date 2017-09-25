//
//  DZNetworkingTests.m
//  DZNetworkingTests
//
//  Created by Nikhil Nigade on 7/10/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <DZNetworking/DZURLSession.h>
#import <DZNetworking/DZJSONResponseParser.h>

/*
 * Thanks to Typicode for the REST Testing API (https://github.com/typicode/jsonplaceholder#how-to)
 */

#define waitForExpectation \
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {\
        if(error) DZLog(@"%@", error.localizedDescription);\
    }];

#define extraQueryParams @"userId=10&Auth=21bghdyu26%30"

@interface DZNetworkingTests : XCTestCase {
    DZURLSession *_session;
}

@end

@implementation DZNetworkingTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    if(!_session)
    {
        _session = [DZURLSession shared];
        _session.baseURL = [NSURL URLWithString:@"http://jsonplaceholder.typicode.com"];
        _session.responseParser = [DZJSONResponseParser new];
        _session.requestModifier = ^(NSURLRequest *request) {
          
            NSMutableURLRequest *req = request.mutableCopy;
            
            NSURL *aURL = req.URL;
            NSString *url = aURL.absoluteString;
            
            if([url containsString:@"?"])
            {
                //already has query params. Append.
                
                url = [url stringByAppendingString:extraQueryParams];
                
            }
            else
            {
                url = [url stringByAppendingFormat:@"?%@", extraQueryParams];
            }
            
            req.URL = [NSURL URLWithString:url];
            
            return req.copy;
            
        };
        
    }
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRequestModifier
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:/post/1"];
    
    [_session GET:@"/posts/1" parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        if ([task.response.URL.absoluteString containsString:extraQueryParams]) {
            [expectation fulfill];
        }
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error.localizedDescription);
    }];
    
    waitForExpectation;
    
}

- (void)testGET
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:/post/1"];
    
    [_session GET:@"/posts/1" parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        if(responseObject &&
           [responseObject isKindOfClass:[NSDictionary class]])
        {
            
            id userId = [responseObject valueForKey:@"userId"];
            
            if(userId && [userId integerValue] == 1)
            {
                [expectation fulfill];
            }
            
        }
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error.localizedDescription);
    }];
    
    waitForExpectation;
    
}

- (void)testPOST
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST:/posts"];
    
    [_session POST:@"/posts" parameters:@{
                                          @"title": @"foo",
                                          @"body": @"bar",
                                          @"userId" : @1
                                          } success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                                              if(responseObject &&
                                                 [responseObject isKindOfClass:[NSDictionary class]])
                                              {
                                                  
                                                  id userId = [responseObject valueForKey:@"userId"];
                                                  
                                                  DZLog(@"Created post with ID: %@", [responseObject valueForKey:@"id"]);
                                                  
                                                  if(userId && [userId integerValue] == 1)
                                                  {
                                                      [expectation fulfill];
                                                  }
                                                  
                                              }
                                          } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                                              DZLog(@"%@", error.localizedDescription);
                                          }];
    
    waitForExpectation;
    
}

- (void)testPOSTWithQuery
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST:/posts"];
    
    [_session POST:@"/posts" queryParams:@{@"foo" : @"bar"}
        parameters:@{
                     @"title": @"foo",
                     @"body": @"bar",
                     @"userId" : @1
                     } success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                         if(responseObject &&
                            [responseObject isKindOfClass:[NSDictionary class]])
                         {
                             
                             id userId = [responseObject valueForKey:@"userId"];
                             
                             DZLog(@"Created post with ID: %@", [responseObject valueForKey:@"id"]);
                             
                             if(userId && [userId integerValue] == 1)
                             {
                                 [expectation fulfill];
                             }
                             
                         }
                     } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                         DZLog(@"%@", error.localizedDescription);
                     }];
    
    waitForExpectation;

    
}

- (void)testPUT
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PUT:/posts/1"];
    
    [_session PUT:@"/posts/1" queryParams:@{@"foo" : @"bar"} parameters:@{
                                           @"title": @"foo",
                                           @"body": @"bar",
                                           @"userId" : @1,
                                           @"id" : @1
                                           } success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                                               if(responseObject &&
                                                  [responseObject isKindOfClass:[NSDictionary class]])
                                               {
                                                   
                                                   [expectation fulfill];
                                                   
                                               }
                                           } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                                               DZLog(@"%@", error.localizedDescription);
                                           }];
    waitForExpectation;
    
}

- (void)testPUTWithQuery
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PUT:/posts/1"];
    
    [_session PUT:@"/posts/1"
      queryParams:@{@"foo" : @"bar"}
       parameters:@{
                    @"title": @"foo",
                    @"body": @"bar",
                    @"userId" : @1,
                    @"id" : @1
                    } success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        if(responseObject &&
                           [responseObject isKindOfClass:[NSDictionary class]])
                        {
                            
                            [expectation fulfill];
                            
                        }
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        DZLog(@"%@", error.localizedDescription);
                    }];
    
    waitForExpectation;
}

- (void)testPATCH
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PATCH:/posts/1"];
    
    [_session PUT:@"/posts/1"
      queryParams:@{@"foo" : @"bar"}
       parameters:@{@"title": @"foo"} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           if(responseObject &&
              [responseObject isKindOfClass:[NSDictionary class]])
           {
               
               [expectation fulfill];
               
           }
       } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           DZLog(@"%@", error.localizedDescription);
       }];
    
    waitForExpectation;
    
}

- (void)testDELETE
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"DELETE:/posts/1"];
    
    [_session DELETE:@"/posts/1" parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        if(response.statusCode <= 204)
        {
            [expectation fulfill];
        }
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error.localizedDescription);
    }];
    
    waitForExpectation;
    
}

@end
