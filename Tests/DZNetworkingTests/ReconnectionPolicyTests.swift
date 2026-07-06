import XCTest
@testable import DZNetworking

final class ReconnectionPolicyTests: XCTestCase {
  
  func testExponentialBackoff() {
    let policy = ReconnectionPolicy(baseDelay: 2, maximumAttempts: 5, maximumDelay: 60, useExponentialBackoff: true)
    
    // attempt 1: 2 * 2^1 = 4
    XCTAssertEqual(policy.nextWaitInterval(for: 1), 4.0)
    // attempt 2: 2 * 2^2 = 8
    XCTAssertEqual(policy.nextWaitInterval(for: 2), 8.0)
    // attempt 3: 2 * 2^3 = 16
    XCTAssertEqual(policy.nextWaitInterval(for: 3), 16.0)
    // attempt 4: 2 * 2^4 = 32
    XCTAssertEqual(policy.nextWaitInterval(for: 4), 32.0)
  }
  
  func testLinearBackoff() {
    let policy = ReconnectionPolicy(baseDelay: 2, maximumAttempts: 5, maximumDelay: 60, useExponentialBackoff: false)
    
    // attempt 1: max(2, 0 * 2) = 2
    XCTAssertEqual(policy.nextWaitInterval(for: 1), 2.0)
    // attempt 2: max(2, 1 * 2) = 2
    XCTAssertEqual(policy.nextWaitInterval(for: 2), 2.0)
    // attempt 3: max(2, 2 * 2) = 4
    XCTAssertEqual(policy.nextWaitInterval(for: 3), 4.0)
    // attempt 4: max(2, 3 * 2) = 6
    XCTAssertEqual(policy.nextWaitInterval(for: 4), 6.0)
  }
  
  func testMaximumDelayLimit() {
    let policy = ReconnectionPolicy(baseDelay: 2, maximumAttempts: 10, maximumDelay: 30, useExponentialBackoff: true)
    
    // attempt 1: 4
    // attempt 2: 8
    // attempt 3: 16
    // attempt 4: 32 -> should cap at 30
    XCTAssertEqual(policy.nextWaitInterval(for: 4), 30.0)
    XCTAssertEqual(policy.nextWaitInterval(for: 5), 30.0)
  }
  
  func testMaximumAttempts() {
    let policy = ReconnectionPolicy(baseDelay: 2, maximumAttempts: 3, maximumDelay: 20, useExponentialBackoff: true)
    
    XCTAssertEqual(policy.nextWaitInterval(for: 1), 4.0)
    XCTAssertEqual(policy.nextWaitInterval(for: 2), 8.0)
    // Attempt 3 should equal maximumAttempts and halt
    XCTAssertEqual(policy.nextWaitInterval(for: 3), .greatestFiniteMagnitude)
    XCTAssertEqual(policy.nextWaitInterval(for: 4), .greatestFiniteMagnitude)
  }
}
