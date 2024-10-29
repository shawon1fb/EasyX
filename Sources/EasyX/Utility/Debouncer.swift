//
//  Debouncer.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//


import Foundation

public class Debouncer {
  private let delay: TimeInterval
  private var workItem: DispatchWorkItem?

  public init(delay: TimeInterval) {
    self.delay = delay
  }

  public func debounce(action: @escaping () -> Void) {
    workItem?.cancel()

    let newWorkItem = DispatchWorkItem(block: action)
    workItem = newWorkItem

    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
  }
}
