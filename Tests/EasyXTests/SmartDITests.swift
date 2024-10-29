//
//  SmartDITests.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//


import XCTest
@testable import EasyX

// Test specific types and mocks
enum TestRoute: Equatable {
    case root
    case parent
    case child
    case grandChild
}

protocol TestProtocol {
    var value: String { get }
}

struct TestImplementation: TestProtocol {
    let value: String
}

final class SmartDITests: XCTestCase {
    // MARK: - Properties
    
    var container: DIContainer!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        container = DIContainer.shared
    }
    
    override func tearDown() {
        container = nil
        super.tearDown()
    }
    
    // MARK: - Basic Registration and Resolution Tests
    
    func testBasicRegistrationAndResolution() {
        let router = { [TestRoute.root] }
        let di = SmartDIImplementation(router: router, container: DIContainer.shared)
        
        di.register(TestProtocol.self) { _ in
            TestImplementation(value: "root")
        }
        
        let resolved: TestProtocol = try! di.resolve()
        XCTAssertEqual(resolved.value, "root")
    }
    
    // MARK: - Scoping Tests
    
    func testNestedScopeResolution() {
        let routes = [TestRoute.root, TestRoute.parent, TestRoute.child]
        var currentRoutes = routes
        let di = SmartDIImplementation(router: { currentRoutes }, container: container)
        
        // Register in root scope
        currentRoutes = [.root]
        di.register(TestProtocol.self) { _ in
            TestImplementation(value: "root")
        }
        
        // Register in parent scope
        currentRoutes = [.root, .parent]
        di.register(TestProtocol.self) { _ in
            TestImplementation(value: "parent")
        }
        
        // Register in child scope
        currentRoutes = [.root, .parent, .child]
        di.register(TestProtocol.self) { _ in
            TestImplementation(value: "child")
        }
        
        // Test resolution from child scope
        let childResolved: TestProtocol = try! di.resolve()
        XCTAssertEqual(childResolved.value, "child")
        
        // Test resolution from parent scope
        currentRoutes = [.root, .parent]
        let parentResolved: TestProtocol = try! di.resolve()
        XCTAssertEqual(parentResolved.value, "parent")
        
        // Test resolution from root scope
        currentRoutes = [.root]
        let rootResolved: TestProtocol = try! di.resolve()
        XCTAssertEqual(rootResolved.value, "root")
    }
    
    func testScopeFallback() {
        let routes = [TestRoute.root, TestRoute.parent, TestRoute.child]
        var currentRoutes = [TestRoute.root]
        let di = SmartDIImplementation(router: { currentRoutes }, container: container)
        
        // Register only in root scope
        di.register(TestProtocol.self, name: "testScopeFallback") { _ in
            TestImplementation(value: "root")
        }
        
        // Test resolution from child scope falls back to root
        currentRoutes = routes
        let resolved: TestProtocol = try! di.resolve(name: "testScopeFallback")
        XCTAssertEqual(resolved.value, "root")
    }
    
    // MARK: - Named Registration Tests
    
    func testNamedRegistrationAndResolution() {
        let di = SmartDIImplementation(router: { [TestRoute.root] }, container: container)
        
        di.register(TestProtocol.self, name: "special") { _ in
            TestImplementation(value: "special")
        }
        
        di.register(TestProtocol.self) { _ in
            TestImplementation(value: "default")
        }
        
        let specialResolved: TestProtocol = try! di.resolve(name: "special")
        let defaultResolved: TestProtocol = try! di.resolve()
        
        XCTAssertEqual(specialResolved.value, "special")
        XCTAssertEqual(defaultResolved.value, "default")
    }
    
    // MARK: - Cleanup Tests
    
    func testScopeCleanup() {
        struct TestImplementation2: TestProtocol {
            let value: String
        }
        
        class ROUTE{
            var routes: [TestRoute] = []
            func getRoutes()->[TestRoute]  { routes }
        }
        
        let route: ROUTE = ROUTE()
        route.routes = [TestRoute.root, TestRoute.parent, TestRoute.child]
        let di = SmartDIImplementation(router: route.getRoutes, container: container)
       
        
       
        
        // Register in child scope
        di.register(TestImplementation2.self) { _ in
            TestImplementation2(value: "child")
        }
        
        route.routes = [TestRoute.root, TestRoute.parent]
        
        di.register(TestImplementation2.self) { _ in
            TestImplementation2(value: "parent")
        }
        
        route.routes = [TestRoute.root, TestRoute.parent, TestRoute.child]
        // Verify registration
        let resolved: TestImplementation2 = try! di.resolve()
        XCTAssertEqual(resolved.value, "child")
        
        let routes2 = [TestRoute.root, TestRoute.parent, TestRoute.child]
        // Cleanup child scope
        di.cleanupScope(routes2)
        
        // Move to parent scope
        route.routes = [TestRoute.root]
        
        // Verify registration is cleaned up
        XCTAssertThrowsError(try {
            let _: TestImplementation2 = try di.resolve()
        }())
    }
    
    // MARK: - Error Handling Tests
    
    func testResolutionFailure() {
        struct TestImplementation3: TestProtocol {
            let value: String
        }
        let di = SmartDIImplementation(router: { [TestRoute.root] }, container: DIContainer.shared)
        
        XCTAssertThrowsError(try {
            let _: TestImplementation3 = try di.resolve()
        }()) { error in
            XCTAssertTrue(error is DIError)
        }
    }
}
