//
//  OSLogClientTests.swift
//
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import XCTest
import OSLog
@testable import OSLogClient

final class OSLogClientTests: XCTestCase {

    let subsystem = "com.cheekyghost.axologl.tests"
    let logCategory = "tests"
    let logger: Logger = .init(subsystem: "com.cheekyghost.axologl.tests", category: "tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!

    override func setUpWithError() throws {
        try super.setUpWithError()
        logDriverSpy = LogDriverSpy(
            id: "unit-tests",
            logSources: [.subsystem(subsystem)]
        )
        logDriverSpyTwo = LogDriverSpy(
            id: "unit-tests-two",
            logSources: [.subsystemAndCategories(subsystem: subsystem, categories: [logCategory])]
        )
        try OSLogClient.initialize(pollingInterval: .custom(1))
        OSLogClient.registerDriver(logDriverSpy)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        OSLogClient.stopPolling()
        OSLogClient._client = nil
        logDriverSpy = nil
    }

    // MARK: - Tests: General

    func test_isInitializedGetter_willReturnExpectedValue() {
        XCTAssertTrue(OSLogClient.isInitialized)
    }

    func test_intervalGetter_willReturnExpectedValue() {
        XCTAssertEqual(OSLogClient.pollingInterval, .custom(1))
    }

    func test_isPolling_willReturnExpectedValue() {
        XCTAssertFalse(OSLogClient.isPolling)
        OSLogClient.startPolling()
        XCTAssertTrue(OSLogClient.isPolling)
        OSLogClient.stopPolling()
        XCTAssertFalse(OSLogClient.isPolling)
    }

    func test_registerDriver_willInvokeClient() async throws {
        let clientSpy = try LogClientPartialSpy(pollingInterval: .custom(1))
        OSLogClient._client = clientSpy
        OSLogClient.registerDriver(logDriverSpy)
        try await wait(for: 0.1)
        XCTAssertTrue(clientSpy.registerDriverCalled)
        XCTAssertTrue(clientSpy.registerDriverParameters?.driver === logDriverSpy)
    }

    func test_deregisterDriver_willInvokeClient() async throws {
        let clientSpy = try LogClientPartialSpy(pollingInterval: .custom(1))
        OSLogClient._client = clientSpy
        OSLogClient.deregisterDriver(withId: logDriverSpy.id)
        try await wait(for: 0.1)
        XCTAssertTrue(clientSpy.deregisterDriverCalled)
        XCTAssertEqual(clientSpy.deregisterDriverParameters?.id, logDriverSpy.id)
    }

    func test_standard_willReceiveExpectedLogs() async throws {
        OSLogClient.startPolling()
        // Log and wait
        logger.trace("This is a trace")
        logger.notice("This is a notice")
        logger.info("This is an info")
        logger.debug("This is a debug")
        logger.warning("This is a warning")
        logger.error("This is an error")
        logger.critical("This is a critical")
        logger.fault("This is a fault")
        logger.log(level: .error, "This is a manual error")
        try await wait(for: 1)
        _ = await OSLogClient.client.pendingPollTask?.result
        // Assert
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 9)
        // Trace
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "This is a trace")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .notice)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "This is a notice")
        // Info
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].message, "This is an info")
        // Debug
        XCTAssertEqual(logDriverSpy.processLogParameterList[3].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[3].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[3].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[3].message, "This is a debug")
        // Warning
        XCTAssertEqual(logDriverSpy.processLogParameterList[4].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[4].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[4].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[4].message, "This is a warning")
        // Error
        XCTAssertEqual(logDriverSpy.processLogParameterList[5].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[5].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[5].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[5].message, "This is an error")
        // Critical
        XCTAssertEqual(logDriverSpy.processLogParameterList[6].level, .fault)
        XCTAssertEqual(logDriverSpy.processLogParameterList[6].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[6].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[6].message, "This is a critical")
        // Fault
        XCTAssertEqual(logDriverSpy.processLogParameterList[7].level, .fault)
        XCTAssertEqual(logDriverSpy.processLogParameterList[7].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[7].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[7].message, "This is a fault")
        // Manual Level (Error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[8].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[8].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[8].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[8].message, "This is a manual error")
    }

    func test_logsOverTime_willNotReceiveDuplicateLogs() async throws {
        OSLogClient.startPolling()
        _ = await OSLogClient.client.pendingPollTask?.result
        // Log and wait
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        _ = await OSLogClient.client.pendingPollTask?.result
        // Assert
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        // Trace
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].message, "log 3")
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        logDriverSpy.reset()
        logger.trace("log 1-2")
        logger.info("log 2-2")
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 2)
        // Trace
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1-2")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2-2")
    }

    func test_logsMadeWhileNotPolling_willReceiveLogsOnNextPoll() async throws {
        OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        OSLogClient.startPolling()
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        // Trace
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].message, "log 3")
    }

    func test_logs_multipleDrivers_willReceiveLogsOnNextPoll() async throws {
        OSLogClient.registerDriver(logDriverSpyTwo)
        OSLogClient.startPolling()
        _ = await OSLogClient.client.pendingPollTask?.result
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        XCTAssertTrue(logDriverSpyTwo.processLogCalled)
        XCTAssertEqual(logDriverSpyTwo.processLogCallCount, 3)
        // Spy One
        // Trace
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2")
        // Notice
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].message, "log 3")
        // Spy Two
        // Trace
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].message, "log 1")
        // Notice
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].message, "log 2")
        // Notice
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].message, "log 3")
    }
}
