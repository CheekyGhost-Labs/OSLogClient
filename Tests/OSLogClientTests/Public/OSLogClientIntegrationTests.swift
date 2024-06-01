//
//  OSLogClientIntegrationTests.swift
//
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import XCTest
import OSLog
@testable import OSLogClient

final class OSLogClientIntegrationTests: XCTestCase {

    let subsystem = "com.cheekyghost.OSLogClient.tests"
    let logCategory = "tests"
    var logClient: LogClient!
    let pollingInterval: PollingInterval = .custom(1)
    let lastProcessedStrategy: LastProcessedStrategy = .userDefaults(key: "com.cheekyghost.OSLogClient.test-processed")
    let logger: Logger = .init(subsystem: "com.cheekyghost.OSLogClient.tests", category: "tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!

    override func setUpWithError() throws {
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        logClient = LogClient(pollingInterval: .custom(1), lastProcessedStrategy: lastProcessedStrategy, logStore: logStore)
        logDriverSpy = LogDriverSpy(
            id: "unit-tests",
            logSources: [.subsystem("com.cheekyghost.OSLogClient.tests")]
        )
        logDriverSpyTwo = LogDriverSpy(
            id: "unit-tests-two",
            logSources: [.subsystemAndCategories(subsystem: "com.cheekyghost.OSLogClient.tests", categories: ["tests"])]
        )
        OSLogClient._client = logClient
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        logClient = nil
        logDriverSpy = nil
        logDriverSpyTwo = nil
    }

    // MARK: - Helpers

    func runAsyncSetup() async {
        await resetPollingToNow()
        await registerListenerSpies()
    }

    func registerListenerSpies() async {
        await OSLogClient.registerDriver(logDriverSpy)
        await OSLogClient.registerDriver(logDriverSpyTwo)
    }

    func resetPollingToNow() async {
        await OSLogClient.pollImmediately()
    }

    func waitForPoll(intervalOverride: UInt64? = nil) async {
        let clientInterval = OSLogClient.pollingInterval.nanoseconds
        let interval = intervalOverride ?? clientInterval
        try? await Task.sleep(nanoseconds: interval)
    }

    // MARK: - Tests: General

    func test_isInitializedGetter_willReturnExpectedValue() {
        XCTAssertTrue(OSLogClient.isInitialized)
    }

    func test_intervalGetter_willReturnExpectedValue() async {
        XCTAssertEqual(OSLogClient.pollingInterval, pollingInterval)
    }

    func test_isPolling_willReturnExpectedValue() async {
        await XCTAssertFalse_async(await OSLogClient.isEnabled)
        await OSLogClient.startPolling()
        await XCTAssertTrue_async(await OSLogClient.isEnabled)
        await OSLogClient.stopPolling()
        await XCTAssertFalse_async(await OSLogClient.isEnabled)
    }

    func test_standard_willReceiveExpectedLogs() async throws {
        await runAsyncSetup()
        await OSLogClient.startPolling()
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

    // MARK: - Tests: Active Polling

    func test_logsOverTime_willNotReceiveDuplicateLogs() async throws {
        await runAsyncSetup()
        await OSLogClient.startPolling()
        _ = await OSLogClient.client.pendingPollTask?.result
        // Log and wait
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        _ = await OSLogClient.client.pendingPollTask?.result
        // Assert
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        XCTAssertTrue(logDriverSpyTwo.processLogCalled)
        XCTAssertEqual(logDriverSpyTwo.processLogCallCount, 3)
        // Trace: Spy One
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1")
        // Trace: Spy Two
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].message, "log 1")
        // Notice: Spy One
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2")
        // Notice: Spy Two
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].message, "log 2")
        // Notice: Spy One
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[2].message, "log 3")
        // Notice: Spy Two
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].level, .error)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[2].message, "log 3")
        // Continue
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        XCTAssertEqual(logDriverSpyTwo.processLogCallCount, 3)
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        XCTAssertEqual(logDriverSpyTwo.processLogCallCount, 3)
        logDriverSpy.reset()
        logDriverSpyTwo.reset()
        logger.trace("log 1-2")
        logger.info("log 2-2")
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertTrue(logDriverSpy.processLogCalled)
        XCTAssertEqual(logDriverSpy.processLogCallCount, 2)
        XCTAssertTrue(logDriverSpyTwo.processLogCalled)
        XCTAssertEqual(logDriverSpyTwo.processLogCallCount, 2)
        // Trace: Spy One
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[0].message, "log 1-2")
        // Trace: Spy Two
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].level, .debug)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[0].message, "log 1-2")
        // Notice: Spy One
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpy.processLogParameterList[1].message, "log 2-2")
        // Notice: Spy Two
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].level, .info)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].subsystem, subsystem)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].category, logCategory)
        XCTAssertEqual(logDriverSpyTwo.processLogParameterList[1].message, "log 2-2")
    }

    // MARK: - Tests: Inactive -> Active Polling

    func test_logsMadeWhileNotPolling_willReceiveLogsOnNextPoll() async throws {
        await runAsyncSetup()
        await OSLogClient.pollImmediately()
        await OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient.startPolling()
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

    func test_logsMadeWhileNotPolling_willReceiveLogsOnImmediatePoll() async throws {
        await runAsyncSetup()
        await OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient.pollImmediately()
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
        // Ensure no duplicates
        logDriverSpy.reset()
        await OSLogClient.pollImmediately()
        // _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        XCTAssertFalse(logDriverSpy.processLogCalled)
    }

    // MARK: - Tests: Force Polling

    func test_pollImmediately_whileActivelyPolling_defaultingToLastProcessed_willNotReceiveDuplicateLogs() async throws {
        await runAsyncSetup()
        await OSLogClient.startPolling()
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
        // Reset spy, log some more items, and poll immediately
        logDriverSpy.reset()
        logger.trace("log 1-2")
        logger.info("log 2-2")
        await OSLogClient.pollImmediately()
        // _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        // XCTAssertTrue(OSLogClient.client.immediatePollTaskMap.isEmpty)
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
        // Reset spy, wait for next polling task to finish, and ensure no duplicates
        await OSLogClient.pollImmediately()
        // _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        logDriverSpy.reset()
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertFalse(logDriverSpy.processLogCalled)
    }

    func test_pollImmediately_whileNotPolling_fromSpecificDate_willReceiveExpectedLogs() async throws {
        await runAsyncSetup()
        let pointInTime = Date().addingTimeInterval(-1) // Now minus a second (want a past date but within this test context)
        await OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient.pollImmediately(from: pointInTime)
        await waitForPoll(intervalOverride: 1)
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
        // Reset and re-run test using fixed point in time
        logDriverSpy.reset()
        await OSLogClient.pollImmediately(from: pointInTime)
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
}
