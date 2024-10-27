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

    var parameterQueue: DispatchQueue = .init(label: "logs", qos: .userInitiated, attributes: .concurrent)

#if os(macOS)
    struct ProcessLogParameters: Sendable {
        var level: LogDriver.LogLevel
        var subsystem: String
        var category: String
        var date: Date
        var message: String
        nonisolated(unsafe) var components: [OSLogMessageComponent]
    }
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
        let params = ProcessLogParameters(
            level: level, subsystem: subsystem, category: category, date: date, message: message, components: components
        )
        parameterQueue.async(flags: .barrier) { [weak self, params] in
            self?.processLogParameterList.append(params)
        }
    }
#else
    struct ProcessLogParameters: Sendable {
        var level: LogDriver.LogLevel
        var subsystem: String
        var category: String
        var date: Date
        var message: String
    }
    var processLogCalled: Bool { processLogCallCount > 0 }
    var processLogCallCount: Int { processLogParameterList.count }
    var processLogParameters: ProcessLogParameters? { processLogParameterList.last }
    var processLogParameterList: [ProcessLogParameters] = []

    override func processLog(level: LogDriver.LogLevel, subsystem: String, category: String, date: Date, message: String) {
        let params = ProcessLogParameters(level: level, subsystem: subsystem, category: category, date: date, message: message)
        parameterQueue.async(flags: .barrier) { [weak self, params] in
            self?.processLogParameterList.append(params)
        }
    }
#endif

    func reset() {
        processLogParameterList.removeAll()
    }
}
