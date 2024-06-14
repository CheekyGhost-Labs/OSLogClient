//
//  LogFilterTests.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

@testable import OSLogClient
import XCTest

final class LogFilterTests: XCTestCase {
    func test_identifier_calculatedAsExpected() {
        // No categories
        let matches = LogFilter.subsystem("system-one")
        XCTAssertEqual(matches.identifier, "subsystem:matches(system-one)")
        let contains = LogFilter.subsystem(contains: "system-one")
        XCTAssertEqual(contains.identifier, "subsystem:contains(system-one)")
        let startsWith = LogFilter.subsystem(startsWith: "system-one")
        XCTAssertEqual(startsWith.identifier, "subsystem:startsWith(system-one)")

        // With Categories
        let matchesCategory = LogFilter.subsystem("system-one", categories: "cat-ui")
        XCTAssertEqual(matchesCategory.identifier, "subsystem:matches(system-one)&[category:matches(cat-ui)]")
        let containsCategory = LogFilter.subsystem(contains: "system-one", categories: "cat-ui")
        XCTAssertEqual(containsCategory.identifier, "subsystem:contains(system-one)&[category:matches(cat-ui)]")
        let startsWithCategory = LogFilter.subsystem(startsWith: "system-one", categories: "cat-ui")
        XCTAssertEqual(startsWithCategory.identifier, "subsystem:startsWith(system-one)&[category:matches(cat-ui)]")
        let matchesRespectsCategory = LogFilter.subsystem("system-one", categories: .startsWith("cat-ui"))
        XCTAssertEqual(matchesRespectsCategory.identifier, "subsystem:matches(system-one)&[category:startsWith(cat-ui)]")
    }

    func test_setRemovesDuplicates() {
        let filters: Set<LogFilter> = [
            LogFilter.subsystem("system-one"),
            LogFilter.subsystem("system-one"),
            LogFilter.subsystem("system-one", categories: "app-ui"), // constrains by category, not a dupe
            LogFilter.subsystem("system-one", categories: "app-ui"),
            LogFilter.subsystem("system-1"),
        ]
        XCTAssertEqual(filters.count, 3)
    }

    func test_subsystemMatchesFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem("system-one")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:matches(system-one)")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "irrelevant"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "irrelevant"))
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "irrelevant"))
    }

    func test_subsystemContainsFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem(contains: "one")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:contains(one)")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "irrelevant"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "irrelevant"))
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "irrelevant"))
    }

    func test_subsystemStartsWithFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem(startsWith: "system-")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:startsWith(system-)")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "irrelevant"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "irrelevant"))
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "subsystem-1", category: "irrelevant"))
    }

    func test_subsystemMatchesWithCategoriesFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem("system-one", categories: "cat-ui")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:matches(system-one)&[category:matches(cat-ui)]")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "cat-ui"))

        // Category does not match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-api"))
        // Subsystem does not match, category does
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "cat-ui"))
        // Neither subsystem nor category match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "cat-api"))
    }

    func test_subsystemContainsWithCategoriesFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem(contains: "one", categories: "cat-ui")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:contains(one)&[category:matches(cat-ui)]")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "cat-ui"))

        // Category does not match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-api"))
        // Subsystem does not match, category does
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "cat-ui"))
        // Neither subsystem nor category match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-1", category: "cat-api"))
    }

    func test_subsystemStartsWithWithCategoriesFilter_willReturnExpectedResults() {
        let subsystemMatches = LogFilter.subsystem(startsWith: "system-", categories: "cat-ui")
        XCTAssertEqual(subsystemMatches.identifier, "subsystem:startsWith(system-)&[category:matches(cat-ui)]")
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "system-ONE", category: "cat-ui"))

        // Category does not match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "system-one", category: "cat-api"))
        // Subsystem does not match, category does
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "subsystem-1", category: "cat-ui"))
        // Neither subsystem nor category match
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "subsystem-1", category: "cat-api"))
    }

    func test_categorySyntaxSugar_willReturnExpectedResults() {
        let categoryFilter = LogCategoryFilter.matches("cat-ui")
        let subsystemMatches = LogFilter.category(categoryFilter)
        XCTAssertEqual(categoryFilter.identifier, subsystemMatches.identifier)
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "irrelevant", category: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstSubsystem: "irrelevant", category: "cat-UI"))
        XCTAssertFalse(subsystemMatches.evaluate(againstSubsystem: "irrelevant", category: "cat-api"))
    }
}
