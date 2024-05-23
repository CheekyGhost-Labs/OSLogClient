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

    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!
    var instanceUnderTest: LogClientPartialSpy!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        logDriverSpy = LogDriverSpy(id: "test")
        logDriverSpyTwo = LogDriverSpy(id: "test-two")
        instanceUnderTest = try LogClientPartialSpy(pollingInterval: .custom(5))
        // Enabling driver registration partials here as the underlying registry is an actor and can't be stubbed
        instanceUnderTest.registerDriverSpy_withDriver.isPartialEnabled = true
        instanceUnderTest.deregisterDriverSpy_withId.isPartialEnabled = true
        instanceUnderTest.isDriverRegisteredSpy_withId_boolOut.isPartialEnabled = true
        // Perma-enabling convenience getter partials
        instanceUnderTest.isPollingEnabledSpy.partialType = .getter
        instanceUnderTest.pollingIntervalSpy.partialType = .getter
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .getter
        instanceUnderTest.lastPolledDateSpy.partialType = .getter
    }

    // MARK: - Tests

    func test_init_willAssignProvidedProperties() async {
        instanceUnderTest.pollingIntervalSpy.partialType = .getter
        let result = await instanceUnderTest.pollingInterval
        XCTAssertEqual(result, .custom(5))
    }

    // MARK: - Tests: Polling: Start/Stop

    func test_startPolling_willUpdateConfig_toIsEnabledTrue() async throws {
        instanceUnderTest.startPollingSpy.isPartialEnabled = true
        // Given
        await XCTAssertFalse_async(await instanceUnderTest.isPollingEnabled)
        await XCTAssertFalse_async(await instanceUnderTest.config.isEnabled)

        // When
        await instanceUnderTest.startPolling()

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.isPollingEnabled)
        await XCTAssertTrue_async(await instanceUnderTest.config.isEnabled)
    }

    func test_startPolling_willExecutePoll() async throws {
        instanceUnderTest.startPollingSpy.isPartialEnabled = true
        instanceUnderTest.executePollSpy.isPartialEnabled = true
        await instanceUnderTest.startPolling()
        XCTAssertEqual(instanceUnderTest.executePollSpy.callCount, 1)
    }

    func test_stopPolling_willDisableFlag() async throws {
        instanceUnderTest.startPollingSpy.isPartialEnabled = true
        instanceUnderTest.stopPollingSpy.isPartialEnabled = true

        // Given
        await instanceUnderTest.startPolling()
        await XCTAssertTrue_async(await instanceUnderTest.isPollingEnabled)
        await XCTAssertTrue_async(await instanceUnderTest.config.isEnabled)

        // When
        await instanceUnderTest.stopPolling()

        // Then
        await XCTAssertFalse_async(await instanceUnderTest.isPollingEnabled)
        await XCTAssertFalse_async(await instanceUnderTest.config.isEnabled)
    }

    func test_stopPolling_willTearDownPendingPollTask() async throws {
        instanceUnderTest.startPollingSpy.isPartialEnabled = true
        instanceUnderTest.stopPollingSpy.isPartialEnabled = true
        // Ensure super getter/setter are used
        instanceUnderTest.pendingPollTaskSpy.partialType = .all
        // Given
        await instanceUnderTest.startPolling()
        let pendingTask = Task.detached(operation: {
            try await Task.sleep(nanoseconds: PollingInterval.custom(1).nanoseconds)
        })
        instanceUnderTest.pendingPollTask = pendingTask

        // When
        await instanceUnderTest.stopPolling()

        // Then
        XCTAssertTrue(pendingTask.isCancelled)
        XCTAssertNil(instanceUnderTest.pendingPollTask)
    }

    // MARK: - Tests: Polling: Update Interval

    func test_updateInterval_withPendingTask_willCancelPendingTask() async {
        instanceUnderTest.stopPollingSpy.isPartialEnabled = true
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true
        // Given
        let pendingTask = Task.detached(operation: {
            try await Task.sleep(nanoseconds: PollingInterval.custom(1).nanoseconds)
        })
        instanceUnderTest.pendingPollTaskSpy.stubbedResult = pendingTask

        // When
        await instanceUnderTest.setPollingInterval(.custom(1))

        // Then
        XCTAssertTrue(pendingTask.isCancelled)
    }

    func test_updateInterval_willAssignIntervalToConfig() async throws {
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true

        // When
        await instanceUnderTest.setPollingInterval(.custom(123))

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .custom(123))
        await XCTAssertEqual_async(await instanceUnderTest.config.pollingInterval, .custom(123))
    }

    func test_updateInterval_pollingEnabled_driversNotEmpty_willInvokeExecutePoll() async {
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true
        await instanceUnderTest.logDriverRegistry.registerDriver(logDriverSpy)
        await instanceUnderTest.config.setIsEnabled(true)
        
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.setPollingInterval(.custom(123))

        // Then
        XCTAssertEqual(instanceUnderTest.executePollSpy.callCount, 1)
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    func test_updateInterval_pollingDisabled_driversNotEmpty_willNotInvokeExecutePoll() async {
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true
        await instanceUnderTest.logDriverRegistry.registerDriver(logDriverSpy)
        await instanceUnderTest.config.setIsEnabled(true)

        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = false
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.setPollingInterval(.custom(123))

        // Then
        XCTAssertFalse(instanceUnderTest.executePollSpy.called)
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    func test_updateInterval_notEnabled_driversNotEmpty_willNotInvokeStartPolling() async {
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true
        await instanceUnderTest.logDriverRegistry.registerDriver(logDriverSpy)
        await instanceUnderTest.config.setIsEnabled(false)

        // Given
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertFalse_async(await instanceUnderTest.config.isEnabled)

        // When
        await instanceUnderTest.setPollingInterval(.custom(123))

        // Then
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    func test_updateInterval_enabled_driversEmpty_willNotInvokeStartPolling() async {
        instanceUnderTest.setPollingIntervalSpy_withInterval.isPartialEnabled = true
        await instanceUnderTest.config.setIsEnabled(true)

        // Given
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertTrue_async(await instanceUnderTest.config.isEnabled)

        // When
        await instanceUnderTest.setPollingInterval(.custom(123))

        // Then
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    // MARK: - Tests: Drivers: isRegistered

    /*
     Note: Usually would spy on an instance of the `LogDriverRegistry`, however, actors don't support inheritance
     so will just assess the instance directly for sanity checks. The `LogDriverRegistry` has it's own dedicated tests.
     */

    func test_isDriverRegistered_driversEmpty_willReturnFalse() async {
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertFalse_async(await instanceUnderTest.isDriverRegistered(withId: "missing"))
        await XCTAssertFalse_async(await instanceUnderTest.isDriverRegistered(withId: logDriverSpy.id))
        await XCTAssertFalse_async(await instanceUnderTest.isDriverRegistered(withId: logDriverSpyTwo.id))
    }

    func test_isDriverRegistered_driversPresent_withUnregisteredDriver_willReturnFalse() async {
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertFalse_async(await instanceUnderTest.isDriverRegistered(withId: "missing"))
    }

    func test_isDriverRegistered_driversPresent_withRegisteredDriver_willReturnFalse() async {
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertTrue_async(await instanceUnderTest.isDriverRegistered(withId: logDriverSpy.id))
    }

    // MARK: - Tests: Drivers: Registering

    func test_registerDriver_willAppendToRegistry() async {
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 1)
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers[0] === logDriverSpy)
    }

    func test_registerDriver_emptyDrivers_pollingEnabled_willInvokeExecutePoll() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        XCTAssertEqual(instanceUnderTest.executePollSpy.callCount, 1)
    }

    func test_registerDriver_emptyDrivers_pollingNotEnabled_willNotStartPolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = false
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    func test_registerDriver_existingDrivers_pollingEnabled_willNotInvokeExecutePolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    func test_registerDriver_existingDrivers_pollingDisabled_willNotInvokeExecutePolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = false
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)

        // When
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        XCTAssertFalse(instanceUnderTest.startPollingSpy.called)
    }

    // MARK: - Tests: Drivers: DeRegistering

    func test_deregisterDriver_driversRemaining_willNotInvokeSoftStopPolling() async {
        // Given
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 1)
        XCTAssertFalse(instanceUnderTest.stopPollingSpy.called)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingEnabled_willInvokeSoftStopPolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = true
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertEqual_async(instanceUnderTest.softStopPollingSpy.callCount, 1)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingDisabled_willNotInvokeSoftStopPolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = false
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = true
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertFalse_async(instanceUnderTest.softStopPollingSpy.called)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversDisabled_pollingEnabled_willNotInvokeSoftStopPolling() async {
        // Given
        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = false
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
        await XCTAssertFalse_async(instanceUnderTest.softStopPollingSpy.called)
    }

    // MARK: - ForcePoll

    func test_forcePoll_pollingEnabled_willAssignPollTask() async throws {
        // Given
        instanceUnderTest.forcePollSpy_withDate.isPartialEnabled = true
        instanceUnderTest.immediatePollTaskMapSpy.partialType = .all
        await instanceUnderTest.config.setIsEnabled(true)
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 0)

        // When
        instanceUnderTest.forcePoll()

        // Then
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 1)
    }

    func test_forcePoll_pollingDisabled_willAssignPollTask() async throws {
        // Given
        instanceUnderTest.forcePollSpy_withDate.isPartialEnabled = true
        instanceUnderTest.immediatePollTaskMapSpy.partialType = .all
        await instanceUnderTest.config.setIsEnabled(false)

        // When
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 0)
        instanceUnderTest.forcePoll()

        // Then
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 1)
    }

    func test_forcePoll_pollingTaskScheduled_willNotEffectPendingPollTask() async throws {
        // Partial setups
        instanceUnderTest.executePollSpy.isPartialEnabled = true
        instanceUnderTest.forcePollSpy_withDate.isPartialEnabled = true
        instanceUnderTest.startPollingSpy.isPartialEnabled = true
        instanceUnderTest.immediatePollTaskMapSpy.partialType = .all
        instanceUnderTest.pendingPollTaskSpy.partialType = .all

        // Given
        await instanceUnderTest.config.setIsEnabled(true)

        // When
        await instanceUnderTest.startPolling()
        let pendingTask = try XCTUnwrap(instanceUnderTest.pendingPollTask)

        // Then
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 0)

        // And when
        instanceUnderTest.forcePoll()

        // Then
        XCTAssertEqual(instanceUnderTest.immediatePollTaskMap.count, 1)
        XCTAssertNotNil(instanceUnderTest.pendingPollTask)
        XCTAssertEqual(instanceUnderTest.pendingPollTask, pendingTask)
    }

    // MARK: - Execute Polling

    func test_executePoll_completion_willReExecutePoll() async {
        // Given
        await instanceUnderTest.setPollingInterval(.custom(1))
        await instanceUnderTest.config.setIsEnabled(true)
        instanceUnderTest.executePollSpy.isPartialEnabled = true
        instanceUnderTest.pendingPollTaskSpy.partialType = .all

        // When
        await instanceUnderTest.executePoll() // Initial poll
        _ = await instanceUnderTest.pendingPollTask?.result // Second poll
        _ = await instanceUnderTest.pendingPollTask?.result // Third poll

        // Then
        XCTAssertEqual(instanceUnderTest.executePollSpy.callCount, 3)
    }

    func test_executePoll_pollingDisabled_willNotExecutePoll() async {
        // Given
        await instanceUnderTest.setPollingInterval(.custom(1))
        await instanceUnderTest.config.setIsEnabled(false)
        instanceUnderTest.executePollSpy.isPartialEnabled = true

        // When
        await instanceUnderTest.executePoll()

        // Then
        XCTAssertNil(instanceUnderTest.pendingPollTask)
    }
}
