//
//  LogClientTests.swift
//  
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import XCTest
@testable import OSLogClient

final class LogClientTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: LogClientPartialSpy!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        instanceUnderTest = try LogClientPartialSpy(pollingInterval: .custom(5))
        instanceUnderTest.registerDriverShouldForwardToSuper = true
        instanceUnderTest.deregisterDriverShouldForwardToSuper = true
    }

    // MARK: - Tests

    func test_init_willAssignProvidedProperties() {
        XCTAssertEqual(instanceUnderTest.pollingInterval, .custom(5))
    }

    func test_updateInterval_withPendingTask_willCancelPendingTask() {
        let pendingTask = Task.detached(operation: {
            try await Task.sleep(nanoseconds: PollingInterval.custom(1).nanoseconds)
        })
        instanceUnderTest.pendingPollTask = pendingTask
        instanceUnderTest.pollingInterval = .custom(1)
        XCTAssertTrue(pendingTask.isCancelled)
    }

    func test_updateInterval_isPollingEnabled_true_willBeginPolling() throws {
        instanceUnderTest.startPolling()
        XCTAssertEqual(instanceUnderTest.executePollCallCount, 1)
        instanceUnderTest.pollingInterval = .custom(3)
        XCTAssertEqual(instanceUnderTest.executePollCallCount, 2)
    }

    func test_startPolling_willEnableFlag() throws {
        XCTAssertFalse(instanceUnderTest.isPollingEnabled)
        instanceUnderTest.startPolling()
        XCTAssertTrue(instanceUnderTest.isPollingEnabled)
    }

    func test_startPolling_willExecutePoll() throws {
        instanceUnderTest.startPolling()
        XCTAssertEqual(instanceUnderTest.executePollCallCount, 1)
    }

    func test_stopPolling_willDisableFlag() throws {
        instanceUnderTest.startPolling()
        XCTAssertTrue(instanceUnderTest.isPollingEnabled)
        instanceUnderTest.stopPolling()
        XCTAssertFalse(instanceUnderTest.isPollingEnabled)
    }

    func test_stopPolling_willTearDownPendingPollTask() throws {
        instanceUnderTest.startPolling()
        let pendingTask = Task.detached(operation: {
            try await Task.sleep(nanoseconds: PollingInterval.custom(1).nanoseconds)
        })
        instanceUnderTest.pendingPollTask = pendingTask
        instanceUnderTest.stopPolling()
        XCTAssertTrue(pendingTask.isCancelled)
        XCTAssertNil(instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_notPresent_willAddToDriversArray() async {
        let driverSpy = LogDriverSpy(id: "test")
        await instanceUnderTest.registerDriver(driverSpy)
        let drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertTrue(drivers.contains(driverSpy))
    }

    func test_registerDriver_alreadyPresent_willNotReAddToDriversArray() async {
        let driverSpy = LogDriverSpy(id: "test")
        await instanceUnderTest.registerDriver(driverSpy)
        await instanceUnderTest.registerDriver(driverSpy)
        await instanceUnderTest.registerDriver(driverSpy)
        await instanceUnderTest.registerDriver(driverSpy)
        let drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertEqual(drivers.count, 1)
        XCTAssertTrue(drivers.contains(driverSpy))
    }

    func test_deregisterDriver_willRemoveToDriversArray() async {
        let driverSpyOne = LogDriverSpy(id: "test-1")
        let driverSpyTwo = LogDriverSpy(id: "test-2")
        await instanceUnderTest.registerDriver(driverSpyOne)
        await instanceUnderTest.registerDriver(driverSpyTwo)
        var drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertEqual(drivers.count, 2)
        XCTAssertTrue(drivers.contains(driverSpyOne))
        XCTAssertTrue(drivers.contains(driverSpyTwo))
        await instanceUnderTest.deregisterDriver(withId: "test-1")
        drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertEqual(drivers.count, 1)
        XCTAssertFalse(drivers.contains(driverSpyOne))
        XCTAssertTrue(drivers.contains(driverSpyTwo))
    }

    func test_deregisterDriver_resultingInEmpty_willTearDownPendingPollTask() async {
        let driverSpy = LogDriverSpy(id: "test")
        await instanceUnderTest.registerDriver(driverSpy)
        var drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertEqual(drivers.count, 1)
        XCTAssertTrue(drivers.contains(driverSpy))
        let pendingTask = Task.detached(operation: {
            try await Task.sleep(nanoseconds: PollingInterval.custom(1).nanoseconds)
        })
        instanceUnderTest.pendingPollTask = pendingTask
        await instanceUnderTest.deregisterDriver(withId: "test")
        drivers = await instanceUnderTest.logPoller.drivers
        XCTAssertEqual(drivers.count, 0)
        XCTAssertTrue(pendingTask.isCancelled)
        XCTAssertNil(instanceUnderTest.pendingPollTask)
    }

    func test_executePoll_completion_willReExecutePoll() async {
        instanceUnderTest.pollingInterval = .custom(1)
        instanceUnderTest.isPollingEnabled = true
        instanceUnderTest.executePollShouldForwardToSuper = true
        instanceUnderTest.executePoll() // Initial poll
        _ = await instanceUnderTest.pendingPollTask?.result // Second poll
        _ = await instanceUnderTest.pendingPollTask?.result // Third poll
        XCTAssertEqual(instanceUnderTest.executePollCallCount, 3)
    }

    func test_executePoll_pollingDisabled_willNotAssignPollTask() async {
        instanceUnderTest.isPollingEnabled = false
        instanceUnderTest.executePollShouldForwardToSuper = true
        instanceUnderTest.executePoll()
        XCTAssertNil(instanceUnderTest.pendingPollTask)
    }
}
