import XCTest

import DZNetworkingTests

var tests = [XCTestCaseEntry]()
tests += DZURLSessionTests.allTests()
tests += FormURLEncodeTests.allTests()
XCTMain(tests)
