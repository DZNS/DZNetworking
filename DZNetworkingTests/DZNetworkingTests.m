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

/*
 * Thanks to Typicode for the REST Testing API (https://github.com/typicode/jsonplaceholder#how-to)
 */

#define waitForExpectation \
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {\
        if(error) DZLog(@"%@", error.localizedDescription);\
    }];\

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
    }
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGET
{
    // This is an example of a functional test case.
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:/post/1"];
    
    [_session GET:@"/posts/1" parameters:nil]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        if(responseObject &&
           [responseObject isKindOfClass:[NSDictionary class]])
        {
            
            id userId = [responseObject valueForKey:@"userId"];
            
            if(userId && [userId integerValue] == 1)
            {
                [expectation fulfill];
            }
            
        }
        
    })
    .catch(^(NSError *error) {
        DZLog(@"%@", error);
    });
    
    waitForExpectation;
    
}

- (void)testPOST
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"POST:/posts"];
    
    [_session POST:@"/posts" parameters:@{
                                          @"title": @"foo",
                                          @"body": @"bar",
                                          @"userId" : @1
                                          }]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
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
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

- (void)testPUT
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PUT:/posts/1"];
    
    [_session PUT:@"/posts/1" parameters:@{
                                           @"title": @"foo",
                                           @"body": @"bar",
                                           @"userId" : @1,
                                           @"id" : @1
                                           }]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        if(responseObject &&
           [responseObject isKindOfClass:[NSDictionary class]])
        {
         
            [expectation fulfill];
            
        }
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

- (void)testPATCH
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"PATCH:/posts/1"];
    
    [_session PUT:@"/posts/1" parameters:@{
                                           @"title": @"foo",
                                          }]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        if(responseObject &&
           [responseObject isKindOfClass:[NSDictionary class]])
        {
            
            [expectation fulfill];
            
        }
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

- (void)testDELETE
{
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"DELETE:/posts/1"];
    
    [_session DELETE:@"/posts/1" parameters:nil]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        if(response.statusCode <= 204)
        {
            [expectation fulfill];
        }
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

@end
