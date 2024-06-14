//
//  LogCategoryFilterTests.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

@testable import OSLogClient
import XCTest

final class LogCategoryFilterTests: XCTestCase {
    func test_identifier_calculatedAsExpected() {
        // String literal ends up as matches
        let stringLiteral: LogCategoryFilter = "cat-ui"
        XCTAssertEqual(stringLiteral.identifier, "category:matches(cat-ui)")

        // Standard convenience creation
        let matches = LogCategoryFilter.matches("cat-ui")
        XCTAssertEqual(matches.identifier, "category:matches(cat-ui)")
        let contains = LogCategoryFilter.contains("cat-ui")
        XCTAssertEqual(contains.identifier, "category:contains(cat-ui)")
        let startsWith = LogCategoryFilter.startsWith("cat-ui")
        XCTAssertEqual(startsWith.identifier, "category:startsWith(cat-ui)")

        // Logic inversion
        let not = LogCategoryFilter.not(.matches("cat-ui"))
        XCTAssertEqual(not.identifier, "not(category:matches(cat-ui))")
    }

    func test_setRemovesDuplicates() {
        let filters: Set<LogCategoryFilter> = [
            LogCategoryFilter.matches("cat-ui"),
            LogCategoryFilter.matches("cat-api"),
            LogCategoryFilter.matches("cat-UI"),
            LogCategoryFilter.startsWith("cat-ui"),
        ]
        XCTAssertEqual(filters.count, 3)
    }

    func test_matchesFilter_willReturnExpectedResults() {
        let subsystemMatches = LogCategoryFilter.matches("cat-ui")
        XCTAssertEqual(subsystemMatches.identifier, "category:matches(cat-ui)")
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-UI"))
        XCTAssertFalse(subsystemMatches.evaluate(againstCategory: "cat-api"))
    }

    func test_containsFilter_willReturnExpectedResults() {
        let subsystemMatches = LogCategoryFilter.contains("ui")
        XCTAssertEqual(subsystemMatches.identifier, "category:contains(ui)")
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-UI"))
        XCTAssertFalse(subsystemMatches.evaluate(againstCategory: "cat-api"))
    }

    func test_startsWithFilter_willReturnExpectedResults() {
        let subsystemMatches = LogCategoryFilter.startsWith("cat-")
        XCTAssertEqual(subsystemMatches.identifier, "category:startsWith(cat-)")
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-ui"))
        XCTAssertTrue(subsystemMatches.evaluate(againstCategory: "cat-UI"))
        XCTAssertFalse(subsystemMatches.evaluate(againstCategory: "app-ui"))
    }

    func test_notFilter_willReturnExpectedResults() {
        let categoryFilter = LogCategoryFilter.matches("cat-ui")
        XCTAssertEqual(categoryFilter.identifier, "category:matches(cat-ui)")
        XCTAssertTrue(categoryFilter.evaluate(againstCategory: "cat-ui"))
        XCTAssertTrue(categoryFilter.evaluate(againstCategory: "cat-UI"))
        XCTAssertFalse(categoryFilter.evaluate(againstCategory: "app-ui"))

        let invertedFilter = LogCategoryFilter.not(categoryFilter)
        XCTAssertEqual(invertedFilter.identifier, "not(category:matches(cat-ui))")
        XCTAssertFalse(invertedFilter.evaluate(againstCategory: "cat-ui"))
        XCTAssertFalse(invertedFilter.evaluate(againstCategory: "cat-UI"))
        XCTAssertTrue(invertedFilter.evaluate(againstCategory: "app-ui"))
    }
}
