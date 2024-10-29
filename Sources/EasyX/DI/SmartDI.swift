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
  static var shared: ISmartDI {
    return SmartDI.shared.getDI()
  }

  func find<T>(name: String? = nil) -> T {
    return SmartDI.DI.find(name: name)
  }
}

public class SmartDI {
  // Singleton instance
  public static let shared = SmartDI()
  public static var DI: ISmartDI {
    shared.getDI()
  }
    
  private init() {}

  // Move the static functionality here
  public func registerSelf<R: Equatable>(stacks: @escaping () -> [R]) {
    let smartDI = SmartDIImplementation(router: stacks)
    DIContainer.shared.register(ISmartDI.self, factory: { _ in smartDI })
  }

  // Helper method to get DI instance
  public func getDI() -> ISmartDI {
    return try! DIContainer.shared.resolve(ISmartDI.self)
  }
}

