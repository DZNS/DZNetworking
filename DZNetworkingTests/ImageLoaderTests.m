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

- (void)testGIF {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:gifImage"];
    
    __block NSURL *URL = [NSURL URLWithString:@"https://bcdn.evilmadscientist.com/media/2018/02/action.gif"];
    
    [SharedImageLoader downloadImageForURL:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        responseObject = nil;
        
        URL =  [NSURL URLWithString:[NSString stringWithFormat:@"https://bcdn.evilmadscientist.com/media/2018/02/action.gif?t=%@", @([NSDate.date timeIntervalSince1970])]];
        
        [SharedImageLoader downloadImageForURL:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            responseObject = nil;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation fulfill];
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            DZLog(@"%@", error);
        }];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error);
    }];
    
    waitForExpectation;
    
}

- (void)testWebP {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"GET:webPimage"];
    
    NSURL *URL = [NSURL URLWithString:@"https://www.gstatic.com/webp/gallery/1.sm.webp"];
    
    [SharedImageLoader downloadImageForURL:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [expectation fulfill];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DZLog(@"%@", error);
    }];
    
    waitForExpectation;
}

@end
