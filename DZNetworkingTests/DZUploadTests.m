//
//  DZUploadTests.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/23/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <DZNetworking/DZUploadSession.h>

#define waitForExpectation \
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {\
    if(error) DZLog(@"%@", error.localizedDescription);\
    }];

@interface DZUploadTests : XCTestCase {
    DZUploadSession *_session;
}

@end

@implementation DZUploadTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    _session = [DZUploadSession shared];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFileUpload
{

    // run the test server and comment the lines below
    XCTAssert(YES, "Passed");
    return;
    // comment the lines above
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"UPLOAD:textFile"];
    
    NSString *URL = @"http://localhost:3000/files";
    
    NSString *str = @"This is some text";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *path = [@"~/Documents/sample.txt" stringByExpandingTildeInPath];
    
    if(![data writeToFile:path atomically:YES])
    {
        DZLog(@"An error occurred when writing the file to the documents directory.");
        waitForExpectation;
        return;
    }
    
    [_session UPLOAD:path fieldName:@"file" URL:URL parameters:nil]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        [expectation fulfill];
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

- (void)testDataUpload
{
    // run the test server and comment the lines below
    XCTAssert(YES, "Passed");
    return;
    // comment the lines above
    XCTestExpectation *expectation = [self expectationWithDescription:@"UPLOAD:textData"];
    
    NSString *URL = @"http://localhost:3000/files";
    
    NSString *str = @"This is some text";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    [_session UPLOAD:data name:@"sample.txt" fieldName:@"file" URL:URL parameters:nil]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        [expectation fulfill];
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error.localizedDescription);
        
    });
    
    waitForExpectation;
    
}

@end
