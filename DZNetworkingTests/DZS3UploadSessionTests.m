//
//  DZS3CredentialsManagerTests.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/25/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <DZNetworking/DZNetworking.h>

#define waitForExpectation \
[self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {\
if(error) DZLog(@"%@", error.localizedDescription);\
}];

@interface DZS3UploadSessionTests : XCTestCase {
    DZS3CredentialsManager *_manager;
}

@end

@implementation DZS3UploadSessionTests

- (void)setUp {
    
    [super setUp];
    _manager = [[DZS3CredentialsManager alloc] initWithKey:@"foo" secret:@"bar"];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testUpload {
    
    // Comment out these two lines to actually run the test. Ensure you've setup your public and private keys. Never commit those to github or any other SCM.
    
    XCTAssert(YES, @"Passes without executing anything.");
    return;
    
    // Comment out the above two lines.
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"UPLOAD:textFile"];
    
    NSString *str = @"Hello world";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *path = [@"~/tmp/sample.txt" stringByExpandingTildeInPath];
    
    [data writeToFile:path atomically:YES];
    
    [DZS3UploadSession shared].credentialsManager = _manager;
    
    [[DZS3UploadSession shared] UPLOAD:path publicKey:@"foo" bucket:@"bucket" path:@"/sample.txt" ACL:nil encryption:nil expires:3600 signature:nil]
    .thenInBackground(^(id responseObject, NSHTTPURLResponse *response, NSURLSessionDataTask *task) {
        
        [expectation fulfill];
        
    })
    .catch(^(NSError *error) {
        
        DZLog(@"%@", error);
        
    });
    
    waitForExpectation;
    
}

@end
