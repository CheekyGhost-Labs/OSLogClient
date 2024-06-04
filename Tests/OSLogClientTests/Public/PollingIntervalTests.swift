//
//  PollingIntervalTests.swift
//  
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import XCTest
@testable import OSLogClient

final class PollingIntervalTests: XCTestCase {

    func test_rawValue_willReturnExpectedValues() throws {
        XCTAssertEqual(PollingInterval.short.rawValue, 10)
        XCTAssertEqual(PollingInterval.medium.rawValue, 30)
        XCTAssertEqual(PollingInterval.long.rawValue, 60)
        XCTAssertEqual(PollingInterval.custom(12).rawValue, 12)
    }

    func test_nanoseconds_willReturnExpectedValues() throws {
        XCTAssertEqual(PollingInterval.short.nanoseconds, 10_000_000_000)
        XCTAssertEqual(PollingInterval.medium.nanoseconds, 30_000_000_000)
        XCTAssertEqual(PollingInterval.long.nanoseconds, 60_000_000_000)
        XCTAssertEqual(PollingInterval.custom(12).nanoseconds, 12_000_000_000)
    }
}
