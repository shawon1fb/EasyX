//
//  DIContainerTests.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//


import XCTest

@testable import EasyX  

class DIContainerTests: XCTestCase {

  var container: DIContainer!

  override func setUp() {
    super.setUp()
    container = DIContainer.shared
  }

  override func tearDown() {
    // Clean up the container after each test
    container = nil
    super.tearDown()
  }

  func testRegisterAndResolveWithScope() {
    struct CUstomType {
      let string: String
    }
    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> CUstomType {
        return CUstomType(string: "Scoped Service")
      }
    }

    let scope = "testScope"

    // When
    container.register(CUstomType.self, factory: ScopedServiceFactory(), scope: scope)

    // Then
    XCTAssertNoThrow(try container.resolve(CUstomType.self, scope: scope))
    XCTAssertEqual(try container.resolve(CUstomType.self, scope: scope).string, "Scoped Service")
    XCTAssertThrowsError(try container.resolve(CUstomType.self))  // Should throw, as it is not registered globally
  }

  func testRegisterAndResolveWithNameAndScope() {
    // Given
    struct ScopedNamedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> Int {
        return 99
      }
    }

    let scope = "testScope"
    let name = "specialNumber"

    // When
    container.register(Int.self, name: name, factory: ScopedNamedServiceFactory(), scope: scope)

    // Then
    XCTAssertNoThrow(try container.resolve(Int.self, name: name, scope: scope))
    XCTAssertEqual(try container.resolve(Int.self, name: name, scope: scope), 99)
    XCTAssertThrowsError(try container.resolve(Int.self, name: name))  // Should throw, as it is not registered globally
  }

  func testDeleteWithScope() {

    struct CustomType {
      let string: String
    }

    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> CustomType {
        return CustomType(string: "Scoped Service")
      }
    }

    let scope = "testScope"
    container.register(CustomType.self, factory: ScopedServiceFactory(), scope: scope)

    // When
    container.delete(CustomType.self, scope: scope)

    // Then
    XCTAssertThrowsError(try container.resolve(CustomType.self, scope: scope))
  }

  func testClearScope() {

    struct ClearScopeModel {
      let string: String
    }

    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> ClearScopeModel {
        return ClearScopeModel(string: "Scoped Service")
      }
    }

    let scope = "testScope"
    container.register(ClearScopeModel.self, factory: ScopedServiceFactory(), scope: scope)

    // When
    container.clearScope(scope)

    // Then
    XCTAssertThrowsError(try container.resolve(ClearScopeModel.self, scope: scope))
  }

  func testHasRegistrationWithScope() {

    struct RegistrationWithScope {
      let string: String
    }

    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> RegistrationWithScope {
        return RegistrationWithScope(string: "Scoped Service")
      }
    }

    let scope = "testScope"

    // When
    container.register(RegistrationWithScope.self, factory: ScopedServiceFactory(), scope: scope)

    // Then
    XCTAssertTrue(container.hasRegistration(RegistrationWithScope.self, scope: scope))
    XCTAssertFalse(container.hasRegistration(RegistrationWithScope.self))
  }

  func testRegisterValue() {
    // Given
    let value = "Test Value"

    // When
    container.registerValue(String.self, value: value)

    // Then
    XCTAssertNoThrow(try container.resolve(String.self))
    XCTAssertEqual(try container.resolve(String.self), value)
  }

  func testSingletonBehavior() {
    // Given
    let container1 = DIContainer.shared
    let container2 = DIContainer.shared

    // When
    container1.registerValue(String.self, value: "Singleton Test")

    // Then
    XCTAssertNoThrow(try container2.resolve(String.self))
    XCTAssertEqual(try container2.resolve(String.self), "Singleton Test")
  }

  func testOverwriteRegistration() {
    // Given
    container.registerValue(String.self, value: "First Value")

    // When
    container.registerValue(String.self, value: "Second Value")

    // Then
    XCTAssertEqual(try container.resolve(String.self), "Second Value")
  }

  func testResolveWithIncorrectType() {
    struct IntService {
      let int: Int
    }
    // Given
    struct IntServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> IntService {
        return IntService(int: 42)
      }
    }
    container.register(IntService.self, factory: IntServiceFactory())

    // When/Then
    XCTAssertThrowsError(try container.resolve(Double.self)) { error in
      XCTAssertEqual(error as? DIError, .serviceNotFound("Double"))
    }
  }

  func testAnonymousFactory() {
    // Given
    container.register(String.self) { _ in "Anonymous Factory" }

    // Then
    XCTAssertEqual(try container.resolve(String.self), "Anonymous Factory")
  }

  func testMultipleRegistrationsWithNames() {

    struct MultipleRegistrationsWithNames {
      let string1: String
    }
    // Given
    container.registerValue(
      MultipleRegistrationsWithNames.self, name: "first",
      value: MultipleRegistrationsWithNames(string1: "First Value"))
    container.registerValue(
      MultipleRegistrationsWithNames.self, name: "second",
      value: MultipleRegistrationsWithNames(string1: "Second Value"))

    // Then
    XCTAssertEqual(
      try container.resolve(MultipleRegistrationsWithNames.self, name: "first").string1,
      "First Value")
    XCTAssertEqual(
      try container.resolve(MultipleRegistrationsWithNames.self, name: "second").string1,
      "Second Value")
    XCTAssertThrowsError(try container.resolve(MultipleRegistrationsWithNames.self))  // No default registration
  }

  func testRegisterAndResolveInDifferentScopes() {
    // Given
    let scope1 = "scope1"
    let scope2 = "scope2"

    container.registerValue(String.self, value: "Global Value")
    container.registerValue(String.self, value: "Scope1 Value", scope: scope1)
    container.registerValue(String.self, value: "Scope2 Value", scope: scope2)

    // Then
    XCTAssertEqual(try container.resolve(String.self), "Global Value")
    XCTAssertEqual(try container.resolve(String.self, scope: scope1), "Scope1 Value")
    XCTAssertEqual(try container.resolve(String.self, scope: scope2), "Scope2 Value")
  }

  func testRegisterMultipleFactoriesForSameType() {
    // Given
    struct ServiceFactoryA: ServiceFactory {
      func resolve(_ resolver: Resolver) -> String {
        return "Service A"
      }
    }
    struct ServiceFactoryB: ServiceFactory {
      func resolve(_ resolver: Resolver) -> String {
        return "Service B"
      }
    }

    // When
    container.register(String.self, name: "A", factory: ServiceFactoryA())
    container.register(String.self, name: "B", factory: ServiceFactoryB())

    // Then
    XCTAssertEqual(try container.resolve(String.self, name: "A"), "Service A")
    XCTAssertEqual(try container.resolve(String.self, name: "B"), "Service B")
  }

  func testRegisterValueWithScope() {

    struct RegisterValueWithScope2 {
      let value: String
    }

    // Given
    let value = "Scoped Value"
    let scope = "testScope"

    // When
    container.registerValue(
      RegisterValueWithScope2.self, value: RegisterValueWithScope2(value: value), scope: scope)

    // Then
    XCTAssertEqual(try container.resolve(RegisterValueWithScope2.self, scope: scope).value, value)
    XCTAssertThrowsError(try container.resolve(RegisterValueWithScope2.self))  // Not registered globally
  }

  func testHasRegistrationWithNameAndScope() {
    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) -> Int {
        return 100
      }
    }

    let scope = "testScope"
    let name = "specialNumber"

    // When
    container.register(Int.self, name: name, factory: ScopedServiceFactory(), scope: scope)

    // Then
    XCTAssertTrue(container.hasRegistration(Int.self, name: name, scope: scope))
    XCTAssertFalse(container.hasRegistration(Int.self, name: name))
  }

  func testDeleteWithNameAndScope() {
    // Given
    struct ScopedServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> Int {
        return 100
      }
    }

    let scope = "testScope"
    let name = "specialNumber"

    container.register(Int.self, name: name, factory: ScopedServiceFactory(), scope: scope)

    // When
    container.delete(Int.self, name: name, scope: scope)

    // Then
    XCTAssertThrowsError(try container.resolve(Int.self, name: name, scope: scope))
  }

  func testClearNonexistentScope() {
    // Given
    let scope = "nonexistentScope"

    // When
    container.clearScope(scope)

    // Then
    // Should not throw any error
  }

  func testResolveAfterClearingScope() {

    struct ResolveAfterClearingScope {
      let string: String
    }
    // Given
    let scope = "testScope"
    container.registerValue(
      ResolveAfterClearingScope.self, value: ResolveAfterClearingScope(string: "Scoped Value"),
      scope: scope)

    // When
    container.clearScope(scope)

    // Then
    XCTAssertThrowsError(try container.resolve(ResolveAfterClearingScope.self, scope: scope))
  }

  func testRegisterDifferentTypesUnderSameName() {
    // Given
    container.registerValue(String.self, name: "commonName", value: "String Value")
    container.registerValue(Int.self, name: "commonName", value: 123)

    // Then
    XCTAssertEqual(try container.resolve(String.self, name: "commonName"), "String Value")
    XCTAssertEqual(try container.resolve(Int.self, name: "commonName"), 123)
  }

  func testRegisterSameTypeDifferentScopesAndNames() {
    // Given
    container.registerValue(String.self, name: "name1", value: "Global Value")
    container.registerValue(String.self, name: "name1", value: "Scoped Value", scope: "scope1")

    // Then
    XCTAssertEqual(try container.resolve(String.self, name: "name1"), "Global Value")
    XCTAssertEqual(
      try container.resolve(String.self, name: "name1", scope: "scope1"), "Scoped Value")
  }

  func testRegisterAnonymousFactoryWithScope() {
    struct RegisterAnonymousFactoryWithScope {
      let string: String
    }
    // Given
    let scope = "testScope"
    container.register(RegisterAnonymousFactoryWithScope.self, scope: scope) { _ in
      RegisterAnonymousFactoryWithScope(string: "Scoped Anonymous Factory")
    }

    // Then
    XCTAssertEqual(
      try container.resolve(RegisterAnonymousFactoryWithScope.self, scope: scope).string,
      "Scoped Anonymous Factory")
    XCTAssertThrowsError(try container.resolve(RegisterAnonymousFactoryWithScope.self))  // Not registered globally
  }

  func testResolveOptionalService() {
    // Given
    struct OptionalServiceFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> String? {
        return nil
      }
    }

    container.register(Optional<String>.self, factory: OptionalServiceFactory())

    // Then
    let result = try? container.resolve(Optional<String>.self)
    XCTAssertNil(result)
  }

  func testResolveServiceDependingOnAnother() {
    // Given
    struct ServiceAFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> String {
        return "Service A"
      }
    }
    struct ServiceBFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> String {
        let serviceA = try resolver.resolve(String.self, name: "ServiceA", scope: nil)  // Force unwrap for simplicity
        return serviceA + " + Service B"
      }
    }

    container.register(String.self, name: "ServiceA", factory: ServiceAFactory())
    container.register(String.self, name: "ServiceB", factory: ServiceBFactory())

    // Then
    XCTAssertEqual(try container.resolve(String.self, name: "ServiceB"), "Service A + Service B")
  }



  func testRegisterAndResolveGenericService() {
    // Given
    class GenericService<T> {
      let value: T
      init(value: T) {
        self.value = value
      }
    }

    struct GenericServiceFactory<T>: ServiceFactory {
      let value: T
      func resolve(_ resolver: Resolver) -> GenericService<T> {
        return GenericService(value: value)
      }
    }

    // When
    container.register(GenericService<Int>.self, factory: GenericServiceFactory(value: 10))
    container.register(GenericService<String>.self, factory: GenericServiceFactory(value: "Hello"))

    // Then
    XCTAssertEqual(try container.resolve(GenericService<Int>.self).value, 10)
    XCTAssertEqual(try container.resolve(GenericService<String>.self).value, "Hello")
  }

  func testCircularDependencyDetection2() {
    // Given
    class ServiceA {
      let serviceB: ServiceB
      init(serviceB: ServiceB) {
        self.serviceB = serviceB
      }
    }

    class ServiceB {
      let serviceA: ServiceA?
      init(serviceA: ServiceA?) {
        self.serviceA = serviceA
      }
    }

    struct ServiceAFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> ServiceA {
        let serviceB = try resolver.resolve(ServiceB.self, name: nil, scope: nil)
        return ServiceA(serviceB: serviceB)
      }
    }

    struct ServiceBFactory: ServiceFactory {
      func resolve(_ resolver: Resolver) throws -> ServiceB {
        do {
          let serviceA = try resolver.resolve(ServiceA.self, name: nil, scope: nil)
          return ServiceB(serviceA: serviceA)
        }
      }
    }

    container.register(ServiceA.self, factory: ServiceAFactory())
    container.register(ServiceB.self, factory: ServiceBFactory())

    // Then
    XCTAssertThrowsError(try container.resolve(ServiceA.self)) { error in
      if case let DIError.circularDependency(services) = error {
          print("------------------------------------------------------------")
          print("circularDependency services: \(services.count)")
          print("circularDependency services: \(ServiceA.self)")
        // Verify that the error contains the correct service names
          var dependency: [String] = []
          
          for service in services {
//              print(service)
              if service.lowercased().contains(String(describing: ServiceA.self).lowercased()){
                  dependency.append(service)
              }
              if service.lowercased().contains(String(describing: ServiceB.self).lowercased()){
                  dependency.append(service)
              }
          }
          print("circularDependency services: \(dependency.count)")
          print("------------------------------------------------------------")
          XCTAssertTrue(dependency.isEmpty == false)
//          XCTAssertTrue(services.first(where: {$0.contains(String(describing: ServiceB.self))}) != nil )
//        XCTAssertTrue(services.contains(String(describing: ServiceB.self)))
      } else {
        XCTFail("Expected circularDependency error, got \(error)")
      }
    }
  }

  func testServiceNotFoundErrorMessage() {
    // When/Then
    do {
      _ = try container.resolve(Float.self)
    } catch let error as DIError {
      switch error {
      case .serviceNotFound(let serviceName):
        XCTAssertEqual(serviceName, "Float")
      default:
        XCTFail("Unexpected error type")
      }

    } catch {
      XCTFail("Unexpected error type")
    }
  }
    
    func testCircularDependencyWithNames() {
        // Given
        struct ServiceAFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) throws -> String {
                let serviceB = try resolver.resolve(String.self, name: "ServiceB", scope: nil)
                return serviceB + " + Service A"
            }
        }
        struct ServiceBFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) throws -> String {
                let serviceA = try resolver.resolve(String.self, name: "ServiceA", scope: nil)
                return serviceA + " + Service B"
            }
        }

        container.register(String.self, name: "ServiceA", factory: ServiceAFactory())
        container.register(String.self, name: "ServiceB", factory: ServiceBFactory())

        // Then
        XCTAssertThrowsError(try container.resolve(String.self, name: "ServiceA")) { error in
            if case let DIError.circularDependency(services) = error {
                // Verify that the error contains the correct service descriptions
                
                print("------------------------------------------------------------")
                print("circularDependency services: \(services.count)")
                
              // Verify that the error contains the correct service names
                var dependency: [String] = []
                
                for service in services {
                    print(service)
                    if service.lowercased().contains(String(describing: String.self).lowercased()){
                        dependency.append(service)
                    }
                  
                }
                print("circularDependency services: \(dependency.count)")
                print("------------------------------------------------------------")
                XCTAssertTrue(dependency.isEmpty == false)
                
                
            } else {
                XCTFail("Expected circularDependency error, got \(error)")
            }
        }
    }

}
