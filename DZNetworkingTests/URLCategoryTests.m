//
//  URLCategoryTests.m
//  DZNetworking
//
//  Created by Nikhil Nigade on 7/30/15.
//  Copyright (c) 2015 Dezine Zync Studios LLP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import <DZNetworking/NSString+URLExtended.h>

@interface URLCategoryTests : XCTestCase

@end

@implementation URLCategoryTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testURI {
    
    NSString *URI = [NSString URIWithFormat:@"/projects/%@", @(230)];
    
    XCTAssert([URI isEqualToString:@"/projects/230"], @"The generated URI did not match the expected result.");
}

- (void)testURL {
    
    NSURL *URL = [NSURL URLWithFormat:@"https://example.com/projects/%@", @(230)];
    
    XCTAssert(URL && [URL.absoluteString isEqualToString:@"https://example.com/projects/230"], @"The generated URL did not match the expected result.");
    
}

@end
