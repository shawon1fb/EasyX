//
//  DIContainerSimpleTest.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//


import XCTest
@testable import EasyX 

class DIContainerSimpleTest: XCTestCase {

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

    func testRegisterAndResolve() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> String {
                return "Test Service"
            }
        }

        // When
        container.register(String.self, factory: TestServiceFactory())

        // Then
        XCTAssertNoThrow(try container.resolve(String.self))
        XCTAssertEqual(try container.resolve(String.self), "Test Service")
    }

    func testRegisterAndResolveWithName() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> Int {
                return 42
            }
        }

        // When
        container.register(Int.self, name: "magic", factory: TestServiceFactory())

        // Then
        XCTAssertNoThrow(try container.resolve(Int.self, name: "magic"))
        XCTAssertEqual(try container.resolve(Int.self, name: "magic"), 42)
    }

    func testResolveUnregisteredService() {
        // When/Then
        XCTAssertThrowsError(try container.resolve(Double.self)) { error in
            XCTAssertEqual(error as? DIError, .serviceNotFound("Double"))
        }
    }

    func testDelete() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> String {
                return "Test Service"
            }
        }
        container.register(String.self, factory: TestServiceFactory())

        // When
        container.delete(String.self)

        // Then
        XCTAssertThrowsError(try container.resolve(String.self))
    }

    func testDeleteWithName() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> Int {
                return 42
            }
        }
        container.register(Int.self, name: "magic", factory: TestServiceFactory())

        // When
        container.delete(Int.self, name: "magic")

        // Then
        XCTAssertThrowsError(try container.resolve(Int.self, name: "magic"))
    }

    func testHasRegistration() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> String {
                return "Test Service"
            }
        }

        // When
        container.register(String.self, factory: TestServiceFactory())

        // Then
        XCTAssertTrue(container.hasRegistration(String.self))
        XCTAssertFalse(container.hasRegistration(Int.self))
    }

    func testHasRegistrationWithName() {
        // Given
        struct TestServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> Int {
                return 42
            }
        }

        // When
        container.register(Int.self, name: "magic", factory: TestServiceFactory())

        // Then
        XCTAssertTrue(container.hasRegistration(Int.self, name: "magic"))
        XCTAssertFalse(container.hasRegistration(Int.self, name: "notMagic"))
    }

    func testMultipleRegistrations() {
        // Given
        struct StringServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> String {
                return "String Service"
            }
        }
        struct IntServiceFactory: ServiceFactory {
            func resolve(_ resolver: Resolver) -> Int {
                return 42
            }
        }

        // When
        container.register(String.self, factory: StringServiceFactory())
        container.register(Int.self, factory: IntServiceFactory())

        // Then
        XCTAssertNoThrow(try container.resolve(String.self))
        XCTAssertNoThrow(try container.resolve(Int.self))
        XCTAssertEqual(try container.resolve(String.self), "String Service")
        XCTAssertEqual(try container.resolve(Int.self), 42)
    }
}
