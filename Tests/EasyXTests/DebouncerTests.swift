//
//  DebouncerTests.swift
//  EasyX
//
//  Created by shahanul on 29/10/24.
//


import XCTest
@testable import EasyX

class DebouncerTests: XCTestCase {
    
    func testDebouncerDelaysExecution() {
        let expectation = self.expectation(description: "Debouncer delays execution")
        let debouncer = Debouncer(delay: 0.1)
        var executionCount = 0
        
        // Call debounce multiple times in quick succession
        for _ in 1...5 {
            debouncer.debounce {
                executionCount += 1
                if executionCount == 1 {
                    expectation.fulfill()
                }
            }
        }
        
        // Wait for slightly longer than the debounce delay
        waitForExpectations(timeout: 0.15)
        
        // Check that the action was only executed once
        XCTAssertEqual(executionCount, 1)
    }
    
    func testDebouncerCancelsAndReschedulesWork() {
        let expectation = self.expectation(description: "Debouncer cancels and reschedules work")
        let debouncer = Debouncer(delay: 0.1)
        var executedValue = 0
        
        // Schedule a work item
        debouncer.debounce {
            executedValue = 1
        }
        
        // Immediately schedule another work item
        debouncer.debounce {
            executedValue = 2
            expectation.fulfill()
        }
        
        // Wait for slightly longer than the debounce delay
        waitForExpectations(timeout: 0.15)
        
        // Check that only the second work item was executed
        XCTAssertEqual(executedValue, 2)
    }
    
    func testDebouncerWithLongerDelay() {
        let expectation = self.expectation(description: "Debouncer works with longer delay")
        let debouncer = Debouncer(delay: 0.5)
        var executionTime: TimeInterval = 0
        let startTime = Date().timeIntervalSince1970
        
        debouncer.debounce {
            executionTime = Date().timeIntervalSince1970 - startTime
            expectation.fulfill()
        }
        
        // Wait for slightly longer than the debounce delay
        waitForExpectations(timeout: 0.6)
        
        // Check that the execution happened after the delay (with some tolerance)
        XCTAssertGreaterThan(executionTime, 0.5)
        XCTAssertLessThan(executionTime, 0.55) // allowing 50ms tolerance
    }
}
