//
//  DZConcurrencyUtilities.swift
//  Networking
//
//  Created by Nikhil Nigade on 09/07/24.
//

import Foundation

internal struct SendableBox<T>: @unchecked Sendable {
  let wrappedValue: T
  
  init(_ wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
  
  func get() -> T {
    wrappedValue
  }
}

internal struct SendableHashableBox<T: Hashable>: @unchecked Sendable {
  let wrappedValue: T
  
  init(_ wrappedValue: T) {
    self.wrappedValue = wrappedValue
  }
  
  func get() -> T {
    wrappedValue
  }
}
