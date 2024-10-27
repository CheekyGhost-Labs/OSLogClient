//
//  OSLogClientIntegrationTests.swift
//
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import OSLog
@testable import OSLogClient
import XCTest

final class OSLogClientIntegration: XCTestCase {
    let subsystem = "com.cheekyghost.OSLogClient.int-tests"
    let logCategory = "int-tests"
    var logClient: LogClient!
    let pollingInterval: PollingInterval = .custom(1)
    let lastProcessedStrategy: LastProcessedStrategy = .userDefaults(key: "com.cheekyghost.OSLogClient.int-test-processed")
    let logger: Logger = .init(subsystem: "com.cheekyghost.OSLogClient.int-tests", category: "int-tests")

    var needsSetup: Bool = true

    override func setUp() async throws {
        guard needsSetup else {
            return
        }
        needsSetup = false
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        logClient = LogClient(pollingInterval: .custom(1), lastProcessedStrategy: lastProcessedStrategy, logStore: logStore)
        await OSLogClient._client.setLogClient(logClient)
    }

    // MARK: - Helpers

    func waitForNextPoll(count: Int = 1) async {
        for _ in 0..<(count + 1) {
            let clientInterval = await OSLogClient.pollingInterval.nanoseconds + 1_000_000_000
            try? await Task.sleep(nanoseconds: clientInterval)
        }
    }

    func makeLogSet(count: Int = 1) -> (groupId: UUID, logs: [String]) {
        let id = UUID()
        var logs: [String] = []
        for i in 0 ..< count {
            logs.append("\(id.uuidString): Log \(i + 1)")
        }
        return (id, logs)
    }

    func makeLogDriverSpy(id: String) -> LogDriverSpy {
        LogDriverSpy(id: id, logFilters: [.subsystem("com.cheekyghost.OSLogClient.int-tests"), .category("int-tests")])
    }

    func waitForSpyProcess(spy: LogDriverSpy) async {
        let expec = expectation(description: "async-wait")
        spy.parameterQueue.async(flags: .barrier) {
            expec.fulfill()
        }
        await fulfillment(of: [expec], timeout: 2)
    }

    // MARK: - Tests: General

    func test_isInitializedGetter_willReturnExpectedValue() async {
        await XCTAssertTrue_async(await OSLogClient.isInitialized)
    }

    func test_intervalGetter_willReturnExpectedValue() async {
        await XCTAssertEqual_async(await OSLogClient.pollingInterval, pollingInterval)
    }

    func test_isPolling_willReturnExpectedValue() async {
        await XCTAssertFalse_async(await OSLogClient.isEnabled)
        await OSLogClient.startPolling()
        await XCTAssertTrue_async(await OSLogClient.isEnabled)
        await OSLogClient.stopPolling()
        await XCTAssertFalse_async(await OSLogClient.isEnabled)
    }

    // MARK: - Standard

    func test_standard_willReceiveExpectedLogs() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        await OSLogClient.startPolling()
        // Make logs
        let logSet = makeLogSet(count: 9)
        logger.trace("\(logSet.logs[0])")
        logger.notice("\(logSet.logs[1])")
        logger.info("\(logSet.logs[2])")
        logger.debug("\(logSet.logs[3])")
        logger.warning("\(logSet.logs[4])")
        logger.error("\(logSet.logs[5])")
        logger.critical("\(logSet.logs[6])")
        logger.fault("\(logSet.logs[7])")
        logger.log(level: .error, "\(logSet.logs[8])")
        // Wait for next polls
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 9)
        // Log 1
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Log 2
        XCTAssertEqual(filteredLogs[1].level, .notice)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Log 3
        XCTAssertEqual(filteredLogs[2].level, .info)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        // Log 4
        XCTAssertEqual(filteredLogs[3].level, .debug)
        XCTAssertEqual(filteredLogs[3].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[3].category, logCategory)
        XCTAssertEqual(filteredLogs[3].message, logSet.logs[3])
        // Log 5
        XCTAssertEqual(filteredLogs[4].level, .error)
        XCTAssertEqual(filteredLogs[4].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[4].category, logCategory)
        XCTAssertEqual(filteredLogs[4].message, logSet.logs[4])
        // Log 6
        XCTAssertEqual(filteredLogs[5].level, .error)
        XCTAssertEqual(filteredLogs[5].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[5].category, logCategory)
        XCTAssertEqual(filteredLogs[5].message, logSet.logs[5])
        // Log 7
        XCTAssertEqual(filteredLogs[6].level, .fault)
        XCTAssertEqual(filteredLogs[6].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[6].category, logCategory)
        XCTAssertEqual(filteredLogs[6].message, logSet.logs[6])
        // Log 8
        XCTAssertEqual(filteredLogs[7].level, .fault)
        XCTAssertEqual(filteredLogs[7].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[7].category, logCategory)
        XCTAssertEqual(filteredLogs[7].message, logSet.logs[7])
        // Log 9
        XCTAssertEqual(filteredLogs[8].level, .error)
        XCTAssertEqual(filteredLogs[8].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[8].category, logCategory)
        XCTAssertEqual(filteredLogs[8].message, logSet.logs[8])
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }

    // MARK: - Tests: Active Polling

    func test_logsOverTime_willNotReceiveDuplicateLogs() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        await OSLogClient.startPolling()
        let logSet = makeLogSet(count: 3)
        // Wait for next poll
        await waitForNextPoll(count: 2)
        // Make Logs
        logger.trace("\(logSet.logs[0])")
        logger.info("\(logSet.logs[1])")
        logger.error("\(logSet.logs[2])")
        // Wait for next poll
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 3)
        // Log 1
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Log 2
        XCTAssertEqual(filteredLogs[1].level, .info)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Log 3
        XCTAssertEqual(filteredLogs[2].level, .error)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        // Reset spy
        logDriverSpy.reset()
        // Wait for next poll
        await waitForNextPoll()
        // Make new logs
        let logSetTwo = makeLogSet(count: 2)
        logger.trace("\(logSetTwo.logs[0])")
        logger.info("\(logSetTwo.logs[1])")
        // Wait for next poll
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogsTwo = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSetTwo.groupId.uuidString) }
        XCTAssertEqual(filteredLogsTwo.count, 2)
        // Log 1
        XCTAssertEqual(filteredLogsTwo[0].level, .debug)
        XCTAssertEqual(filteredLogsTwo[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[0].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[0].message, logSetTwo.logs[0])
        // Log 2
        XCTAssertEqual(filteredLogsTwo[1].level, .info)
        XCTAssertEqual(filteredLogsTwo[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[1].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[1].message, logSetTwo.logs[1])
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }

    // MARK: - Tests: Inactive -> Active Polling

    func test_logsMadeWhileNotPolling_willReceiveLogsOnNextPoll() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        let logSet = makeLogSet(count: 3)
        await OSLogClient.stopPolling()
        await OSLogClient.pollImmediately()
        logger.trace("\(logSet.logs[0])")
        logger.info("\(logSet.logs[1])")
        logger.error("\(logSet.logs[2])")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient.startPolling()
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 3)
        // Trace
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Notice
        XCTAssertEqual(filteredLogs[1].level, .info)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Notice
        XCTAssertEqual(filteredLogs[2].level, .error)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }

    func test_logsMadeWhileNotPolling_willReceiveLogsOnImmediatePoll() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        let logSet = makeLogSet(count: 3)
        let pointInTime = Date().addingTimeInterval(-3) // Now minus three seconds (want a past date but within this test context)
        await OSLogClient.stopPolling()
        logger.trace("\(logSet.logs[0])")
        logger.info("\(logSet.logs[1])")
        logger.error("\(logSet.logs[2])")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient._client.logClient.setLastProcessedDate(pointInTime)
        await OSLogClient.pollImmediately(from: pointInTime)
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.category == logCategory && $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 3)
        // Trace
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Notice
        XCTAssertEqual(filteredLogs[1].level, .info)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Notice
        XCTAssertEqual(filteredLogs[2].level, .error)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        // Ensure no duplicates
        logDriverSpy.reset()
        await OSLogClient.pollImmediately()
        XCTAssertFalse(logDriverSpy.processLogCalled)
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }

    // MARK: - Tests: Force Polling

    func test_pollImmediately_whileActivelyPolling_defaultingToLastProcessed_willNotReceiveDuplicateLogs() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        let logSet = makeLogSet(count: 3)
        await OSLogClient.startPolling()
        _ = await OSLogClient._client.logClient.pendingPollTask?.result
        // Log and wait
        logger.trace("\(logSet.logs[0])")
        logger.info("\(logSet.logs[1])")
        logger.error("\(logSet.logs[2])")
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 3)
        // Trace
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Notice
        XCTAssertEqual(filteredLogs[1].level, .info)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Notice
        XCTAssertEqual(filteredLogs[2].level, .error)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        await waitForNextPoll()
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        await waitForNextPoll()
        XCTAssertEqual(logDriverSpy.processLogCallCount, 3)
        // Reset spy, log some more items, and poll immediately
        logDriverSpy.reset()
        let logSetTwo = makeLogSet(count: 2)
        logger.trace("\(logSetTwo.logs[0])")
        logger.info("\(logSetTwo.logs[1])")
        // Poll now
        await OSLogClient.pollImmediately()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogsTwo = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSetTwo.groupId.uuidString) }
        XCTAssertEqual(filteredLogsTwo.count, 2)
        // Trace
        XCTAssertEqual(filteredLogsTwo[0].level, .debug)
        XCTAssertEqual(filteredLogsTwo[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[0].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[0].message, logSetTwo.logs[0])
        // Notice
        XCTAssertEqual(filteredLogsTwo[1].level, .info)
        XCTAssertEqual(filteredLogsTwo[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[1].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[1].message, logSetTwo.logs[1])
        // Reset spy, wait for next polling task to finish, and ensure no duplicates
        await OSLogClient.pollImmediately()
        // _ = await OSLogClient.client.immediatePollTaskMap.first?.value.result
        logDriverSpy.reset()
        _ = await OSLogClient._client.logClient.pendingPollTask?.result
        XCTAssertFalse(logDriverSpy.processLogCalled)
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }

    func test_pollImmediately_whileNotPolling_fromSpecificDate_willReceiveExpectedLogs() async throws {
        let logDriverSpy = makeLogDriverSpy(id: #function)
        await logClient.registerDriver(logDriverSpy)
        let logSet = makeLogSet(count: 3)
        let pointInTime = Date().addingTimeInterval(-1) // Now minus a second (want a past date but within this test context)
        await OSLogClient.stopPolling()
        // Log
        logger.trace("\(logSet.logs[0])")
        logger.info("\(logSet.logs[1])")
        logger.error("\(logSet.logs[2])")
        // Assert
        XCTAssertFalse(logDriverSpy.processLogCalled)
        await OSLogClient.pollImmediately(from: pointInTime)
        await waitForNextPoll()
        await waitForSpyProcess(spy: logDriverSpy)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogs = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogs.count, 3)
        // Trace
        XCTAssertEqual(filteredLogs[0].level, .debug)
        XCTAssertEqual(filteredLogs[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[0].category, logCategory)
        XCTAssertEqual(filteredLogs[0].message, logSet.logs[0])
        // Notice
        XCTAssertEqual(filteredLogs[1].level, .info)
        XCTAssertEqual(filteredLogs[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[1].category, logCategory)
        XCTAssertEqual(filteredLogs[1].message, logSet.logs[1])
        // Notice
        XCTAssertEqual(filteredLogs[2].level, .error)
        XCTAssertEqual(filteredLogs[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogs[2].category, logCategory)
        XCTAssertEqual(filteredLogs[2].message, logSet.logs[2])
        // Reset and re-run test using fixed point in time
        logDriverSpy.reset()
        await OSLogClient.pollImmediately(from: pointInTime)
        // Filter by log id (should be only returned set, but for brevity)
        let filteredLogsTwo = logDriverSpy.processLogParameterList.filter{ $0.message.contains(logSet.groupId.uuidString) }
        XCTAssertEqual(filteredLogsTwo.count, 3)
        // Trace
        XCTAssertEqual(filteredLogsTwo[0].level, .debug)
        XCTAssertEqual(filteredLogsTwo[0].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[0].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[0].message, logSet.logs[0])
        // Notice
        XCTAssertEqual(filteredLogsTwo[1].level, .info)
        XCTAssertEqual(filteredLogsTwo[1].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[1].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[1].message, logSet.logs[1])
        // Notice
        XCTAssertEqual(filteredLogsTwo[2].level, .error)
        XCTAssertEqual(filteredLogsTwo[2].subsystem, subsystem)
        XCTAssertEqual(filteredLogsTwo[2].category, logCategory)
        XCTAssertEqual(filteredLogsTwo[2].message, logSet.logs[2])
        // Deregister
        await logClient.deregisterDriver(withId: #function)
    }
}
