//
//  ReconnectionPolicy.swift
//  DZNetworking
//
//  Created by Nikhil Nigade on 06/07/26.
//

import Foundation

// MARK: - ReconnectionPolicy

public struct ReconnectionPolicy {
  let baseDelay: TimeInterval
  let maximumAttempts: UInt
  let maximumDelay: TimeInterval
  let useExponentialBackoff: Bool

  public init(baseDelay: TimeInterval = 2, maximumAttempts: UInt = 5, maximumDelay: TimeInterval = 60, useExponentialBackoff: Bool = true) {
    precondition(baseDelay < maximumDelay, "baseDelay should always be less than maximumDelay")
    precondition((baseDelay * Double(maximumAttempts)) < maximumDelay, "baseDelay should always be less than maximumDelay")

    self.baseDelay = baseDelay
    self.maximumAttempts = maximumAttempts
    self.maximumDelay = maximumDelay
    self.useExponentialBackoff = useExponentialBackoff
  }

  func nextWaitInterval(for attempt: UInt) -> TimeInterval {
    precondition(attempt > 0, "Attempt should always be greater than 0")

    guard attempt < maximumAttempts else {
      // Caller should check against this value, when yielded, reattempts should halt.
      return .greatestFiniteMagnitude
    }

    let delay: TimeInterval

    if useExponentialBackoff {
      delay = min(maximumDelay, baseDelay * Double(pow(Double(2), Double(attempt))))
    }
    else {
      // Linearly solve
      delay = min(maximumDelay, max(baseDelay, Double(attempt - 1) * baseDelay))
    }

    return delay
  }
}
