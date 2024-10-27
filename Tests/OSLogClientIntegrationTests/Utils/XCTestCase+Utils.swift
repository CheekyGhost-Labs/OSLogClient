//
//  XCTestCase.swift
//  
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func wait(for duration: TimeInterval) async throws {
        try await Task.detached(priority: .userInitiated) {
            try await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)
        }.result.get()
    }

    public func XCTAssertEqual_async<T>(
        _ expression1: @autoclosure () async throws -> T,
        _ expression2: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows where T : Equatable {
        let result1 = try await expression1()
        let result2 = try await expression2()
        XCTAssertEqual(result1, result2, message(), file: file, line: line)
    }

    public func XCTAssertTrue_async(
        _ expression: @autoclosure () async throws -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        let result = try await expression()
        XCTAssertTrue(result, message(), file: file, line: line)
    }

    public func XCTAssertFalse_async(
        _ expression: @autoclosure () async throws -> Bool,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        let result = try await expression()
        XCTAssertFalse(result, message(), file: file, line: line)
    }

    public func XCTAssertNil_async(
        _ expression: @autoclosure () async throws -> Any?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        let result = try await expression()
        XCTAssertNil(result, message(), file: file, line: line)
    }

    public func XCTAssertNotNil_async(
        _ expression: @autoclosure () async throws -> Any?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async rethrows {
        let result = try await expression()
        XCTAssertNotNil(result, message(), file: file, line: line)
    }

    public func XCTUnwrap_async<T>(
        _ expression: @autoclosure () async throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let result = try await expression()
        return try XCTUnwrap(result, message(), file: file, line: line)
    }
}
