//
//  DIContainer.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//

import Foundation

public enum DIError: Error, Equatable {
  case serviceNotFound(String)
  case circularDependency([String])

  public static func == (lhs: DIError, rhs: DIError) -> Bool {
    switch (lhs, rhs) {
    case (.serviceNotFound(let left), .serviceNotFound(let right)):
      return left == right
    case (.circularDependency(let left), .circularDependency(let right)):
      return left == right
    default:
      return false
    }
  }
}

public protocol ServiceFactory {
  associatedtype Service
  func resolve(_ resolver: Resolver) throws -> Service
}

public protocol Resolver: AnyObject {
  func resolve<T>(_ serviceType: T.Type, name: String?, scope: String?) throws -> T
}

public class DIContainer {
  private struct AnyServiceFactory {
    private let _resolve: (Resolver) throws -> Any

    init<Factory: ServiceFactory>(_ factory: Factory) {
      self._resolve = { resolver in
        try factory.resolve(resolver)
      }
    }

    func resolve(_ resolver: Resolver) throws -> Any {
      return try _resolve(resolver)
    }
  }

  private struct AnonymousFactory<T>: ServiceFactory {
    let factory: (Resolver) throws -> T
    func resolve(_ resolver: Resolver) throws -> T {
      return try factory(resolver)
    }
  }

  private var registrations: [ObjectIdentifier: [String: AnyServiceFactory]] = [:]
  private var scopedRegistrations: [String: [ObjectIdentifier: [String: AnyServiceFactory]]] = [:]

  public static let shared = DIContainer()

  private init() {}

  public func register<Factory: ServiceFactory>(
    _ serviceType: Factory.Service.Type, name: String? = nil, factory: Factory, scope: String? = nil
  ) {
    let key = ObjectIdentifier(serviceType)
    var nameDict =
      scope == nil ? registrations[key] ?? [:] : (scopedRegistrations[scope!]?[key] ?? [:])
    nameDict[name ?? ""] = AnyServiceFactory(factory)

    if let scope = scope {
      if scopedRegistrations[scope] == nil {
        scopedRegistrations[scope] = [:]
      }
      scopedRegistrations[scope]?[key] = nameDict
    } else {
      registrations[key] = nameDict
    }
  }

  public func register<T>(
    _ serviceType: T.Type, name: String? = nil, factory: @escaping (Resolver) throws -> T,
    scope: String? = nil
  ) {
    register(serviceType, name: name, factory: AnonymousFactory(factory: factory), scope: scope)
  }

  public func registerValue<T>(
    _ serviceType: T.Type, name: String? = nil, value: T, scope: String? = nil
  ) {
    register(serviceType, name: name, factory: { _ in value }, scope: scope)
  }

  public func resolve<T>(_ serviceType: T.Type, name: String? = nil, scope: String? = nil) throws
    -> T
  {
    let key = ServiceKey(type: ObjectIdentifier(serviceType), name: name, scope: scope)

    // Check for circular dependency
    if Thread.resolutionStack.contains(key) {
      let cycle = Thread.resolutionStack + [key]
      let serviceDescriptions = cycle.map { key in
        let typeName = String(describing: key.type)
        let namePart = key.name ?? "default"
        let scopePart = key.scope ?? "global"
        return "\(typeName)(name: \(namePart), scope: \(scopePart), type: \(serviceType))"
      }
      throw DIError.circularDependency(serviceDescriptions)
    }

    // Add current service to the resolution stack
    Thread.resolutionStack.append(key)
    defer {
      // Remove current service from the resolution stack after resolving
      Thread.resolutionStack.removeLast()
    }

    if let scope = scope, let scopedDict = scopedRegistrations[scope],
      let nameDict = scopedDict[key.type], let factory = nameDict[name ?? ""]
    {
      guard let service = try factory.resolve(self) as? T else {
        throw DIError.serviceNotFound(String(describing: serviceType))
      }
      return service
    }

    guard let nameDict = registrations[key.type], let factory = nameDict[name ?? ""] else {
      throw DIError.serviceNotFound(String(describing: serviceType))
    }

    guard let service = try factory.resolve(self) as? T else {
      throw DIError.serviceNotFound(String(describing: serviceType))
    }

    return service
  }

  public func delete<T>(_ serviceType: T.Type, name: String? = nil, scope: String? = nil) {
    let key = ObjectIdentifier(serviceType)

    if let scope = scope {
      scopedRegistrations[scope]?[key]?[name ?? ""] = nil
      if scopedRegistrations[scope]?[key]?.isEmpty == true {
        scopedRegistrations[scope]?[key] = nil
      }
      if scopedRegistrations[scope]?.isEmpty == true {
        scopedRegistrations[scope] = nil
      }
    } else {
      registrations[key]?[name ?? ""] = nil
      if registrations[key]?.isEmpty == true {
        registrations[key] = nil
      }
    }
  }

  public func hasRegistration<T>(_ serviceType: T.Type, name: String? = nil, scope: String? = nil)
    -> Bool
  {
    let key = ObjectIdentifier(serviceType)
    if let scope = scope {
      return scopedRegistrations[scope]?[key]?[name ?? ""] != nil
    }
    return registrations[key]?[name ?? ""] != nil
  }

  public func clearScope(_ scope: String) {
    scopedRegistrations[scope] = nil
  }

 
}

extension Thread {
  private static let resolutionStackKey = "DIContainerResolutionStackKey"

  static var resolutionStack: [ServiceKey] {
    get {
      return (Thread.current.threadDictionary[resolutionStackKey] as? [ServiceKey]) ?? []
    }
    set {
      Thread.current.threadDictionary[resolutionStackKey] = newValue
    }
  }
}

extension DIContainer: Resolver {}



//MARK: Printers
extension DIContainer {
    // Prints all registered services in a formatted way, organized by scope
    public func printRegistrations() {
      print("\n=== DIContainer Registrations ===\n")

      // Print global registrations
      print("Global Registrations:")
      if registrations.isEmpty {
        print("  No global registrations")
      } else {
        for (typeId, nameDict) in registrations.sorted(by: {
          String(describing: $0.key) < String(describing: $1.key)
        }) {
          let typeName = String(describing: typeId)
            print("  TypeID: \(typeName)")
            print("  Type: \(typeId.getTypeName())")
          for (name, _) in nameDict.sorted(by: { $0.key < $1.key }) {
            let displayName = name.isEmpty ? "default" : name
            print("    - Name: \(displayName)")
          }
        }
      }

      // Print scoped registrations
      print("\nScoped Registrations:")
      if scopedRegistrations.isEmpty {
        print("  No scoped registrations")
      } else {
        for (scope, typeDict) in scopedRegistrations.sorted(by: { $0.key < $1.key }) {
          print("\nScope: \(scope)")
          for (typeId, nameDict) in typeDict.sorted(by: {
            String(describing: $0.key) < String(describing: $1.key)
          }) {
            let typeName = String(describing: typeId)
            print("  TypeID: \(typeName)")
            print("  Type: \(typeId.getTypeName())")
            for (name, _) in nameDict.sorted(by: { $0.key < $1.key }) {
              let displayName = name.isEmpty ? "default" : name
              print("    - Name: \(displayName)")
            }
          }
        }
      }
      print("\n===============================\n")
    }
    
    // Prints registered types in a more readable format
    public func printRegisteredTypes() {
        print("\n=== Registered Types ===")
        
        // Print global registrations
        print("\nGlobal Registrations:")
        for (typeId, nameDict) in registrations {
            let typeName = typeId.getTypeName()
            print("- \(typeName)")
            for (name, _) in nameDict {
                let displayName = name.isEmpty ? "default" : name
                print("  └─ \(displayName)")
            }
        }
        
        // Print scoped registrations
        print("\nScoped Registrations:")
        for (scope, typeDict) in scopedRegistrations {
            print("\nScope: \(scope)")
            for (typeId, nameDict) in typeDict {
                let typeName = typeId.getTypeName()
                print("- \(typeName)")
                for (name, _) in nameDict {
                    let displayName = name.isEmpty ? "default" : name
                    print("  └─ \(displayName)")
                }
            }
        }
        print("\n=====================")
    }
}




extension ObjectIdentifier {
    /// Attempts to get a human-readable type name from the ObjectIdentifier
    func getTypeName() -> String {
        // Using runtime reflection to get the type name
        let typePtr = unsafeBitCast(self, to: Any.Type.self)
        let typeName = String(describing: typePtr)
        
        // Clean up the type name
        return cleanupTypeName(typeName)
    }
    
    private func cleanupTypeName(_ rawName: String) -> String {
        // Remove common prefixes and suffixes that might appear in the type name
        var name = rawName
            .replacingOccurrences(of: "Swift.", with: "")
            .replacingOccurrences(of: "ObjectIdentifier", with: "")
        
        // If the name contains a module prefix (e.g., "MyModule.MyType"),
        // you might want to keep only the type name
        if let lastDotIndex = name.lastIndex(of: ".") {
            name = String(name[name.index(after: lastDotIndex)...])
        }
        
        return name
    }
}

