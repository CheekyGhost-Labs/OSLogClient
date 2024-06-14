//
//  ArrayLogCategoryFilterIdentifierTests.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

@testable import OSLogClient
import XCTest

final class ArrayLogCategoryFilterIdentifierTests: XCTestCase {
    func test_identifier_withNoItems_outputsExpectedValue() {
        let filters: [LogCategoryFilter] = []
        XCTAssertEqual(filters.identifier, "<no-filters>")
    }

    func test_identifier_withSingleItem_outputsExpectedValue() {
        let filters: [LogCategoryFilter] = [
            .matches("cat-ui"),
        ]
        XCTAssertEqual(filters.identifier, "category:matches(cat-ui)")
    }

    func test_identifier_moreThanOneItem_outputsExpectedValue() {
        let filters: [LogCategoryFilter] = [
            .matches("cat-ui"),
            .matches("cat-api"),
        ]
        XCTAssertEqual(filters.identifier, "category:matches(cat-ui),category:matches(cat-api)")
    }
}
