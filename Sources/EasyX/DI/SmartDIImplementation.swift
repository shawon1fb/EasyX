//
//  SmartDIImplementation.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//
import OSLog
import SwiftUI

public final class SmartDIImplementation<Route: Equatable>: ISmartDI {
  public func find<T>(name: String? = nil) -> T {
    do {
      return try resolve(name: name)
    } catch {
      fatalError("Dependency \(T.self) not found in any accessible scope")
    }
  }

  let logger: Logger = .init(subsystem: "SmartDI", category: "SmartDI")
  private let router: () -> [Route]
  private let container: DIContainer
  @MainActor
  public init(router: @escaping () -> [Route], container: DIContainer = .shared) {
    self.router = router
    self.container = container
  }

  // Get the current route path as a scope
  private func getCurrentScope() -> String {
    return router().map { "\($0)" }.joined(separator: "/")
  }

  // Get all possible parent scopes including current scope
  private func getAllPossibleScopes() -> [String] {
    let routeComponents = router().map { "\($0)" }
    var scopes: [String] = []
    var currentPath = ""

    for component in routeComponents {
      currentPath += (currentPath.isEmpty ? "" : "/") + component
      scopes.append(currentPath)
    }

    // Return scopes from most specific to least specific
    return scopes.reversed()
  }

  public func resolve<T>(name: String? = nil) throws -> T {
    // Try resolving from most specific scope to least specific
    let scopes = getAllPossibleScopes()
    logger.info("Trying to resolve \(T.self) in \(scopes)")

    for scope in scopes {
      do {
        let v = try container.resolve(T.self, name: name, scope: scope)
        logger.log("Resolved \(T.self) in \(scope)")
        return v
      } catch DIError.serviceNotFound {
        continue  // Try next scope if service not found in current scope
      } catch {
        // Rethrow other errors
        //fatalError("Error resolving \(T.self): \(error)")
        throw error
      }
    }

    throw DIError.serviceNotFound("\(T.self)")
    // If we get here, the dependency wasn't found in any scope
    // fatalError("Dependency \(T.self) not found in any accessible scope")
  }

  public func register<T>(
    _ serviceType: T.Type, name: String? = nil, factory: @escaping (Resolver) throws -> T
  ) {
    let scope = getCurrentScope()
    logger.debug("Registering \(serviceType) in \(scope)")
    container.register(serviceType, name: name, factory: factory, scope: scope)
  }

  // Optional: Method to manually cleanup scopes when needed
  public func cleanupScope(_ route: [Route]) {
    let scopePath =
      route
      .map { "\($0)" }
      .joined(separator: "/")
    container.clearScope(scopePath)
  }

  public func resolve<T>(_ serviceType: T.Type, name: String? = nil, scope: String? = nil) throws
    -> T
  {
    // If specific scope is provided, try that first
    if let scope = scope {
      do {
        let result = try container.resolve(serviceType, name: name, scope: scope)
        logger.log("Resolved \(T.self) in specific scope: \(scope)")
        return result
      } catch DIError.serviceNotFound {
        // If not found in specific scope, fall through to scope hierarchy
        logger.debug("Service \(T.self) not found in specific scope \(scope), trying hierarchy")
      } catch {
        // Rethrow other errors
        logger.error("Error resolving \(T.self) in scope \(scope): \(error)")
        throw error
      }
    }

    // Get all possible scopes from current route
    let scopes = getAllPossibleScopes()
    logger.info("Trying to resolve \(T.self) in scopes: \(scopes)")

    // Try resolving from most specific scope to least specific
    for scopePath in scopes {
      do {
        let result = try container.resolve(serviceType, name: name, scope: scopePath)
        logger.log("Resolved \(T.self) in scope: \(scopePath)")
        return result
      } catch DIError.serviceNotFound {
        continue  // Try next scope if service not found in current scope
      } catch {
        // Rethrow other errors
        logger.error("Error resolving \(T.self): \(error)")
        throw error
      }
    }

    // Finally, try resolving from global scope
    do {
      let result = try container.resolve(serviceType, name: name, scope: nil)
      logger.log("Resolved \(T.self) in global scope")
      return result
    } catch {
      logger.error("Failed to resolve \(T.self) in any scope: \(error)")
      throw DIError.serviceNotFound("\(T.self)")
    }
  }
}
