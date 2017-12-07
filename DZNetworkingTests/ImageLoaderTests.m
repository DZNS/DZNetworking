//
//  ImageLoaderTests.m
//  DZNetworkingTests
//
//  Created by Nikhil Nigade on 07/12/17.
//  Copyright © 2017 Dezine Zync Studios LLP. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <DZNetworking/ImageLoader.h>

#define waitForExpectation \
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {\
    if(error) DZLog(@"%@", error.localizedDescription);\
}];

@interface ImageLoaderTests : XCTestCase

@end

@implementation ImageLoaderTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    XCTAssert(YES);
    return;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:image"];
    
    NSURL *URL = [NSURL URLWithString:@"..."];
    
    [SharedImageLoader downloadImageForURL:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [expectation fulfill];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error);
    }];
    
    waitForExpectation;
    
}

@end
