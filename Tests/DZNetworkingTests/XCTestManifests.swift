import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(DZURLSessionTests.allTests),
    testCase(FormURLEncodeTests.allTests),
  ]
}
#endif
