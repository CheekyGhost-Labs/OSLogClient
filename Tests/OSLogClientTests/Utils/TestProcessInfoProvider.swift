//
//  TestProcessInfoProvider.swift
//
//
//  Created by Michael O'Brien on 2/6/2024.
//

import Foundation
@testable import OSLogClient

/// `ProcessInfoEnvironmentProvider` instance that injects a run-time unit-test driven argument for facilitating some unit tests.
class TestProcessInfoProvider: ProcessInfoEnvironmentProvider {

    var processInfoEnvironment: [String : String] {
        var base = ProcessInfo.processInfo.environment
        base["OSLOGCLIENT_UNIT_TESTING"] = "1"
        return base
    }
}
