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
}
