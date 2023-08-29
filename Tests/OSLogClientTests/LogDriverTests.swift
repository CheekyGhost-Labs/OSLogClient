//
//  LogDriverTests.swift
//  
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import XCTest
@testable import OSLogClient

final class LogDriverTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: LogDriver!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        instanceUnderTest = LogDriver(id: "test-id")
    }

    // MARK: - Tests

    func test_init_willAssignProvidedProperties() {
        XCTAssertEqual(instanceUnderTest.id, "test-id")
    }

    func test_isLogValid_subsystemFilter_willReturnExpectedResults() {
        instanceUnderTest.addLogSources([
            .subsystem("system-one"),
            .subsystem("system-two")
        ])
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "any"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "any"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "any"))
    }

    func test_isLogValid_subsystemAndCategoriesFilter_willReturnExpectedResults() {
        instanceUnderTest.addLogSources([
            .subsystemAndCategories(subsystem: "system-one", categories: ["cat-ui"]),
            .subsystemAndCategories(subsystem: "system-two", categories: ["cat-api", "cat-errors"]),
            .subsystemAndCategories(subsystem: "system-three", categories: ["cat-ui", "cat-api", "cat-errors"]),
        ])
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "cat-ui"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "cat-api"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "cat-errors"))

        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-ui"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-api"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-errors"))

        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-ui"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-api"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-errors"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "random"))
    }

    func test_isLogValid_mixedFilters_willReturnExpectedResults() {
        instanceUnderTest.addLogSources([
            .subsystem("system-one"),
            .subsystemAndCategories(subsystem: "system-two", categories: ["cat-ui", "cat-api"]),
        ])
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "cat-ui"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-one", category: "cat-api"))

        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-ui"))
        XCTAssertTrue(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-api"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-two", category: "cat-errors"))

        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-ui"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-api"))
        XCTAssertFalse(instanceUnderTest.isValidLogSource(subsystem: "system-three", category: "cat-errors"))
    }
}
