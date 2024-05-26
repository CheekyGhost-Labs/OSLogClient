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
    var logClient: LogClient!
    let logger: Logger = .init(subsystem: "com.cheekyghost.axologl.tests", category: "tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!

    override func setUpWithError() throws {
        logClient = try LogClient(pollingInterval: .custom(1), logStore: nil)
        logDriverSpy = LogDriverSpy(
            id: "unit-tests",
            logSources: [.subsystem("com.cheekyghost.axologl.tests")]
        )
        logDriverSpyTwo = LogDriverSpy(
            id: "unit-tests-two",
            logSources: [.subsystemAndCategories(subsystem: "com.cheekyghost.axologl.tests", categories: ["tests"])]
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
        await registerListenerSpies()
        await resetPollingToNow()
    }

    func registerListenerSpies() async {
        await logClient.registerDriver(logDriverSpy)
        await logClient.registerDriver(logDriverSpyTwo)
    }

    func resetPollingToNow() async {
        OSLogClient.pollImmediately()
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
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

    func test_isDriverRegisteredWithId_willReturnFalse_whenDriverIsNotRegistered() async throws {
        let clientSpy = try LogClientPartialSpy(pollingInterval: .custom(1))
        OSLogClient._client = clientSpy
        try await wait(for: 0.1)
        let isRegistered = await clientSpy.isDriverRegistered(withId: logDriverSpy.id)
        XCTAssertFalse(isRegistered)
    }

    func test_isDriverRegisteredWithId_willReturnTrue_whenDriverIsRegistered() async throws {
        let clientSpy = try LogClientPartialSpy(pollingInterval: .custom(1))
        clientSpy.registerDriverShouldForwardToSuper = true
        clientSpy.isDriverRegisteredShouldForwardToSuper = true
        OSLogClient._client = clientSpy
        OSLogClient.registerDriver(logDriverSpy)
        try await wait(for: 0.1)
        let isRegistered = await clientSpy.isDriverRegistered(withId: logDriverSpy.id)
        XCTAssertTrue(isRegistered)
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
        await runAsyncSetup()
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

    // MARK: - Tests: Active Polling

    func test_logsOverTime_willNotReceiveDuplicateLogs() async throws {
        await runAsyncSetup()
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

    // MARK: - Tests: Inactive -> Active Polling

    func test_logsMadeWhileNotPolling_willReceiveLogsOnNextPoll() async throws {
        await runAsyncSetup()
        OSLogClient.pollImmediately()
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

    func test_logsMadeWhileNotPolling_willReceiveLogsOnImmediatePoll() async throws {
        await runAsyncSetup()
        OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        OSLogClient.pollImmediately()
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
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
        OSLogClient.pollImmediately()
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        XCTAssertFalse(logDriverSpy.processLogCalled)
    }

    // MARK: - Tests: Force Polling

    func test_pollImmediately_multiple_willQueueExpectedTasks_and_willRemoveWhenCompleted() async throws {
        await runAsyncSetup()
        XCTAssertTrue(OSLogClient.client.immediatePollTaskMap.isEmpty)
        OSLogClient.pollImmediately(from: nil)
        OSLogClient.pollImmediately(from: Date().addingTimeInterval(-3600))
        OSLogClient.pollImmediately(from: Date().addingTimeInterval(-86400))
        XCTAssertEqual(OSLogClient.client.immediatePollTaskMap.count, 3)
        let keys = OSLogClient.client.immediatePollTaskMap.map(\.key)
        let taskOne = OSLogClient.client.immediatePollTaskMap[keys[0]]
        let taskTwo = OSLogClient.client.immediatePollTaskMap[keys[1]]
        let taskThree = OSLogClient.client.immediatePollTaskMap[keys[2]]
        _ = await taskOne?.result
        _ = await taskTwo?.result
        _ = await taskThree?.result
        XCTAssertTrue(OSLogClient.client.immediatePollTaskMap.isEmpty)
    }

    func test_pollImmediately_whileActivelyPolling_defaultingToLastProcessed_willNotReceiveDuplicateLogs() async throws {
        await runAsyncSetup()
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
        // Reset spy, log some more items, and poll immediately
        logDriverSpy.reset()
        logger.trace("log 1-2")
        logger.info("log 2-2")
        OSLogClient.pollImmediately()
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        XCTAssertTrue(OSLogClient.client.immediatePollTaskMap.isEmpty)
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
        logDriverSpy.reset()
        _ = await OSLogClient.client.pendingPollTask?.result
        XCTAssertFalse(logDriverSpy.processLogCalled)
    }

    func test_pollImmediately_whileNotPolling_fromSpecificDate_willReceiveExpectedLogs() async throws {
        await runAsyncSetup()
        let pointInTime = Date().addingTimeInterval(-1) // Now minus a second (want a past date but within this test context)
        OSLogClient.stopPolling()
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        OSLogClient.pollImmediately(from: pointInTime)
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
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
        OSLogClient.pollImmediately(from: pointInTime)
        _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
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

    // MARK: - Tests: Driver Broadcasting

    func test_logs_multipleDrivers_willReceiveLogsOnNextPoll() async throws {
        await runAsyncSetup()
        OSLogClient.startPolling()
        _ = await OSLogClient.client.pendingPollTask?.result
        logger.trace("log 1")
        logger.info("log 2")
        logger.error("log 3")
        try await wait(for: 1)
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
