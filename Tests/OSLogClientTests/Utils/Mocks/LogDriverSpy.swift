//
//  LogDriverSpy.swift
//
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import OSLog
@testable import OSLogClient

class LogDriverSpy: LogDriver, @unchecked Sendable {
#if os(macOS)
    typealias ProcessLogParameters = (
        level: LogDriver.LogLevel,
        subsystem: String,
        category: String,
        date: Date,
        message: String,
        components: [OSLogMessageComponent]
    )
    var processLogCalled: Bool { processLogCallCount > 0 }
    var processLogCallCount: Int { processLogParameterList.count }
    var processLogParameters: ProcessLogParameters? { processLogParameterList.last }
    var processLogParameterList: [ProcessLogParameters] = []

    override func processLog(
        level: LogLevel,
        subsystem: String,
        category: String,
        date: Date,
        message: String,
        components: [OSLogMessageComponent]
    ) {
        processLogParameterList.append((level, subsystem, category, date, message, components))
    }
#else
    typealias ProcessLogParameters = (level: LogDriver.LogLevel, subsystem: String, category: String, date: Date, message: String)
    var processLogCalled: Bool { processLogCallCount > 0 }
    var processLogCallCount: Int { processLogParameterList.count }
    var processLogParameters: ProcessLogParameters? { processLogParameterList.last }
    var processLogParameterList: [ProcessLogParameters] = []

    override func processLog(level: LogDriver.LogLevel, subsystem: String, category: String, date: Date, message: String) {
        processLogParameterList.append((level, subsystem, category, date, message))
    }
#endif

    func reset() {
        processLogParameterList.removeAll()
    }
}
