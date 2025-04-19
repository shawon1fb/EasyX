//
//  SmartDI.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//

import OSLog
import SwiftUI

public protocol ISmartDI {
  func find<T>(name: String?) -> T
  func resolve<T>(name: String?) throws -> T
  func register<T>(_ serviceType: T.Type, name: String?, factory: @escaping (Resolver) throws -> T)
  func resolve<T>(_ serviceType: T.Type, name: String?, scope: String?) throws
    -> T
}
extension ISmartDI {
  @MainActor
  static var shared: ISmartDI {
    return SmartDI.shared.getDI()
  }
  @MainActor
  func find<T>(name: String? = nil) -> T {
    return SmartDI.DI.find(name: name)
  }
}

public class SmartDI {
  // Singleton instance
  @MainActor
  public static let shared = SmartDI()
  @MainActor
  public static var DI: ISmartDI {
    shared.getDI()
  }

  private init() {}

  // Move the static functionality here
  @MainActor
  public func registerSelf<R: Equatable>(stacks: @escaping () -> [R]) {
    let smartDI = SmartDIImplementation(router: stacks)
    DIContainer.shared.register(ISmartDI.self, factory: { _ in smartDI })
  }

  // Helper method to get DI instance
  @MainActor
  public func getDI() -> ISmartDI {
    return try! DIContainer.shared.resolve(ISmartDI.self)
  }
}
