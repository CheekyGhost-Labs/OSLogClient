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

    let dateStub = Date().addingTimeInterval(-3600)
    let logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "unit-tests")
    let lastProcessedDefaultsKey: String = "test-key"
    let pollingInterval: PollingInterval = .custom(1)
    var logStore: OSLogStore!
    var lastProcessedStrategy: LastProcessedStrategy!
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!
    var instanceUnderTest: LogClient!
    var testProcessInfoProvider: TestProcessInfoProvider!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        logStore = try OSLogStore(scope: .currentProcessIdentifier)
        logDriverSpy = LogDriverSpy(id: "test")
        logDriverSpyTwo = LogDriverSpy(id: "test-two")
        testProcessInfoProvider = TestProcessInfoProvider()
        lastProcessedStrategy = .userDefaults(key: lastProcessedDefaultsKey)
        instanceUnderTest = LogClient(
            pollingInterval: pollingInterval,
            lastProcessedStrategy: lastProcessedStrategy,
            logStore: logStore,
            logger: logger,
            processInfoEnvironmentProvider: testProcessInfoProvider
        )
    }

    /**
     NOTE: Using direct assessment, and presence of expected objects (polling task etc) as unable to subclass (and therefore spy on)
     actor instances. This is annoying, but understandable due to the nature of an Actor.
     */

    // MARK: - Tests: Drivers: Lifecycle

    func test_init_public_willAssignProvidedProperties() async throws {
        let instance = LogClient(
            pollingInterval: .custom(123),
            lastProcessedStrategy: .userDefaults(key: "test-key"),
            logStore: logStore,
            logger: logger
        )
        await XCTAssertEqual_async(await instance.pollingInterval, .custom(123))
        let strategy = try await XCTUnwrap_async(await instance.lastProcessedStrategy as? UserDefaultsLastProcessedStrategy)
        await XCTAssertEqual_async(strategy.key, "test-key")
        await XCTAssertTrue_async(await instance.logStore === logStore)
        // Logger does not conform to Equatable (and subsystem/category is unaccessible) :(
    }

    func test_init_internal_willAssignProvidedProperties() async throws {
        let instance = LogClient(
            pollingInterval: .custom(123),
            drivers: [logDriverSpy, logDriverSpyTwo],
            lastProcessedStrategy: .userDefaults(key: "test-key"),
            logStore: logStore,
            logger: logger,
            processInfoEnvironmentProvider: testProcessInfoProvider
        )
        await XCTAssertEqual_async(await instance.pollingInterval, .custom(123))
        await XCTAssertEqual_async(await instance.drivers, [logDriverSpy, logDriverSpyTwo])
        let strategy = try await XCTUnwrap_async(await instance.lastProcessedStrategy as? UserDefaultsLastProcessedStrategy)
        await XCTAssertEqual_async(strategy.key, "test-key")
        await XCTAssertTrue_async(await instance.logStore === logStore)
        // Logger does not conform to Equatable (and subsystem/category is unaccessible) :(
    }

    // MARK: - Tests: Should Pause Flag Helper

    func test_setShouldPauseIfNoRegisteredDrivers_false_willAssignProvidedFlagToProperty() async {
        // Given
        await XCTAssertTrue_async(await instanceUnderTest.shouldPauseIfNoRegisteredDrivers)

        // When
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)

        // Then
        await XCTAssertFalse_async(await instanceUnderTest.shouldPauseIfNoRegisteredDrivers)
    }

    func test_setShouldPauseIfNoRegisteredDrivers_true_willAssignProvidedFlagToProperty() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await XCTAssertFalse_async(await instanceUnderTest.shouldPauseIfNoRegisteredDrivers)

        // When
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.shouldPauseIfNoRegisteredDrivers)
    }

    // MARK: - Tests: Last Processed Date Helpers

    func test_loadLastProcessedDate_userDefaults_missing_willReturnNil() async {
        UserDefaults.standard.removeObject(forKey: lastProcessedDefaultsKey)
        await XCTAssertNil_async(await instanceUnderTest.lastProcessedDate)
    }

    func test_loadLastProcessedDate_userDefaults_present_willReturnStoredDate() async {
        UserDefaults.standard.setValue(dateStub.timeIntervalSince1970, forKey: lastProcessedDefaultsKey)
        let result = await instanceUnderTest.lastProcessedDate
        XCTAssertEqual(result?.timeIntervalSince1970, dateStub.timeIntervalSince1970)
    }

    func test_loadLastProcessedDate_inMemory_missing_willReturnNil() async {
        let instance = LogClient(
            pollingInterval: .custom(1),
            lastProcessedStrategy: .inMemory,
            logStore: logStore,
            logger: logger,
            processInfoEnvironmentProvider: testProcessInfoProvider
        )
        await instance.setLastProcessedDate(nil)
        await XCTAssertNil_async(await instance.lastProcessedDate)
    }

    func test_loadLastProcessedDate_inMemory_present_willReturnStoredDate() async {
        let instance = LogClient(
            pollingInterval: .custom(1),
            lastProcessedStrategy: .inMemory,
            logStore: logStore,
            logger: logger,
            processInfoEnvironmentProvider: testProcessInfoProvider
        )
        await instance.setLastProcessedDate(dateStub)
        let result = await instance.lastProcessedDate
        XCTAssertEqual(result?.timeIntervalSince1970, dateStub.timeIntervalSince1970)
    }

    func test_setLastProcessedDate_userDefaults_willStoreToDefaults_and_willAssignToProperty() async {
        // Given
        await instanceUnderTest.setLastProcessedDate(nil)
        UserDefaults.standard.removeObject(forKey: lastProcessedDefaultsKey)
        XCTAssertNil(UserDefaults.standard.value(forKey: lastProcessedDefaultsKey))
        await XCTAssertNil_async(await instanceUnderTest.lastProcessedDate)

        // When
        await instanceUnderTest.setLastProcessedDate(dateStub)

        // Then
        XCTAssertEqual(UserDefaults.standard.value(forKey: lastProcessedDefaultsKey) as? TimeInterval, dateStub.timeIntervalSince1970)
        await XCTAssertEqual_async(await instanceUnderTest.lastProcessedDate?.timeIntervalSince1970, dateStub.timeIntervalSince1970)
    }

    func test_setLastProcessedDate_inMemory_willNotStoreToDefaults_and_willAssignToProperty() async {
        let instance = LogClient(
            pollingInterval: .custom(1),
            lastProcessedStrategy: .inMemory,
            logStore: logStore,
            logger: logger,
            processInfoEnvironmentProvider: testProcessInfoProvider
        )
        // Given
        await instance.setLastProcessedDate(nil)
        UserDefaults.standard.removeObject(forKey: lastProcessedDefaultsKey)
        XCTAssertNil(UserDefaults.standard.value(forKey: lastProcessedDefaultsKey))
        await XCTAssertNil_async(await instance.lastProcessedDate)

        // When
        await instance.setLastProcessedDate(dateStub)

        // Then
        XCTAssertNil(UserDefaults.standard.value(forKey: lastProcessedDefaultsKey))
        await XCTAssertEqual_async(await instance.lastProcessedDate?.timeIntervalSince1970, dateStub.timeIntervalSince1970)
    }

    // MARK: - Tests: Drivers: Registration

    func test_init_hasExpectedProperties() async throws {
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
    }

    func test_isDriverRegistered_idPresent_willReturnTrue() async {
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertTrue_async(await instanceUnderTest.isDriverRegistered(withId: logDriverSpy.id))
    }

    func test_isDriverRegistered_idMissing_willReturnFalse() async {
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.isDriverRegistered(withId: "missing"))
    }

    func test_registerDriver_notRegistered_willAppendToDriversArray() async {
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [logDriverSpy])
    }

    func test_registerDriver_alreadyRegistered_willNotAppendToDriversArray() async {
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [logDriverSpy])
    }

    func test_deRegisterDriver_willRemoveProvidedIdOnly() async {
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [logDriverSpy, logDriverSpyTwo])
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [logDriverSpyTwo])
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [logDriverSpyTwo])
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)
        await XCTAssertEqual_async(await instanceUnderTest.drivers, [])
    }

    // MARK: - Tests: Drivers: Registration: Poll Execution

    func test_registerDriver_emptyDrivers_pollingEnabled_shouldPauseIfNoRegisteredDriversTrue_willInvokeExecutePoll() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await XCTAssertTrue_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.pendingPollTask?.cancel()
        await instanceUnderTest._testSetPendingPollTask(nil)
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        await XCTAssertNotNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_emptyDrivers_pollingEnabled_shouldPauseIfNoRegisteredDriversFalse_willNotInvokeExecutePoll() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await XCTAssertTrue_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.pendingPollTask?.cancel()
        await instanceUnderTest._testSetPendingPollTask(nil)
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_emptyDrivers_pollingDisabled_shouldPauseIfNoRegisteredDriversTrue_willNotStartPolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await XCTAssertTrue_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_emptyDrivers_pollingDisabled_shouldPauseIfNoRegisteredDriversFalse_willNotStartPolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await XCTAssertTrue_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.registerDriver(logDriverSpy)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_existingDrivers_pollingEnabled_shouldPauseIfNoRegisteredDriversTrue_willNotInvokeExecutePolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.pendingPollTask?.cancel()
        await instanceUnderTest._testSetPendingPollTask(nil)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_existingDrivers_pollingEnabled_shouldPauseIfNoRegisteredDriversFalse_willNotInvokeExecutePolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.pendingPollTask?.cancel()
        await instanceUnderTest._testSetPendingPollTask(nil)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_existingDrivers_pollingDisabled_shouldPauseIfNoRegisteredDriversTrue_willNotInvokeExecutePolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_registerDriver_existingDrivers_pollingDisabled_shouldPauseIfNoRegisteredDriversFalse_willNotInvokeExecutePolling() async {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await XCTAssertFalse_async(await instanceUnderTest.drivers.isEmpty)
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.registerDriver(logDriverSpyTwo)

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    // MARK: - Tests: DeRegistration: Soft Stop Polling

    func test_deregisterDriver_driversRemaining_willNotInvokeSoftStopPolling() async {
        // Given
        await instanceUnderTest.startPolling()
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        let pendingTask = Task<(), Error> {}
        await instanceUnderTest._testSetPendingPollTask(pendingTask)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.drivers.count, 1)
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingEnabled_willInvokeSoftStopPolling() async {
        // Given
        await instanceUnderTest.startPolling()
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        let pendingTask = Task<(), Error> {}
        await instanceUnderTest._testSetPendingPollTask(pendingTask)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.drivers.count, 0)
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingDisabled_willNotInvokeSoftStopPolling() async {
        // Given
        await instanceUnderTest.stopPolling()
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(true)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertEqual_async(await instanceUnderTest.drivers.count, 2)
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
        // Forcefully assigning a dummy pending task here. Would not be teared down as result of `stopPolling` call assigned after `stopPolling`.
        let pendingTask = Task<(), Error> {}
        await instanceUnderTest._testSetPendingPollTask(pendingTask)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.drivers.count, 0)
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
        // Pending task not effected (soft stop)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)
    }

    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversDisabled_pollingEnabled_willNotInvokeSoftStopPolling() async {
        // Given
        await instanceUnderTest.startPolling()
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await instanceUnderTest.registerDriver(logDriverSpy)
        await instanceUnderTest.registerDriver(logDriverSpyTwo)
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
        // Forcefully assigning a dummy pending task here. Would not be teared down as result of `stopPolling` call assigned after `stopPolling`.
        let pendingTask = Task<(), Error> {}
        await instanceUnderTest._testSetPendingPollTask(pendingTask)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)

        // When
        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)

        // Then
        await XCTAssertEqual_async(await instanceUnderTest.drivers.count, 0)
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)
    }

    // MARK: - Tests: Polling: Start/Stop

    func test_startPolling_willUpdateConfig_toIsEnabledTrue() async throws {
        // Given
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)

        // When
        await instanceUnderTest.startPolling()

        // Then
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
    }

    func test_startPolling_noDrivers_shouldPauseIfNoRegisteredDriversTrue_willNotExecutePoll() async throws {
        // Given
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)

        // When
        await instanceUnderTest.startPolling()

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_startPolling_noDrivers_shouldPauseIfNoRegisteredDriversFalse_willExecutePoll() async throws {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)

        // When
        await instanceUnderTest.startPolling()

        // Then
        await XCTAssertNotNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_startPolling_driversPresent_shouldPauseIfNoRegisteredDriversTrue_willExecutePoll() async throws {
        // Given
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
        await instanceUnderTest.registerDriver(logDriverSpy)

        // When
        await instanceUnderTest.startPolling()

        // Then
        await XCTAssertNotNil_async(await instanceUnderTest.pendingPollTask)
    }

    func test_stopPolling_willDisableFlag() async throws {
        // Given
        await instanceUnderTest.startPolling()
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)

        // When
        await instanceUnderTest.stopPolling()

        // Then
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
    }

    func test_stopPolling_pendingPollTask_willTearDownPendingPollTask() async throws {
        // Given
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await instanceUnderTest.startPolling()
        let pendingTask = try await XCTUnwrap_async(await instanceUnderTest.pendingPollTask)

        // When
        await instanceUnderTest.stopPolling()

        // Then
        XCTAssertTrue(pendingTask.isCancelled)
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }

    // MARK: - Immediate Poll

    func test_pollImmediately_pollingEnabled_willInvokePollFromDate() async throws {
        // Given
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.pollImmediately()

        // Then
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsCallCount, 1)
    }

    func test_pollImmediately_pollingDisabled_willInvokePollFromDate() async throws {
        // Given
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.pollImmediately()

        // Then
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsCallCount, 1)
    }

    func test_pollImmediately_pollingTaskScheduled_willNotEffectPendingPollTask() async throws {
        // When
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)
        await instanceUnderTest.startPolling()
        let pendingTask = try await XCTUnwrap_async(await instanceUnderTest.pendingPollTask)

        // Then
        await XCTAssertFalse_async(await instanceUnderTest._testPollLatestLogsCalled)

        // And when
        await instanceUnderTest.pollImmediately()

        // Then
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsCallCount, 1)
        await XCTAssertNotNil_async(await instanceUnderTest.pendingPollTask)
        await XCTAssertEqual_async(await instanceUnderTest.pendingPollTask, pendingTask)
    }

    func test_pollImmediately_repeatedCalls_willInvokeAsReceived() async throws {
        let dateTwo = Date().addingTimeInterval(-7200)
        let dateThree = Date().addingTimeInterval(-10_800)
        let dateFour = Date().addingTimeInterval(-14_400)
        // When
        await instanceUnderTest.setShouldPauseIfNoRegisteredDrivers(false)

        // Then
        await XCTAssertFalse_async(await instanceUnderTest._testPollLatestLogsCalled)

        // And when
        await instanceUnderTest.pollImmediately()
        await instanceUnderTest.pollImmediately(from: dateTwo)
        await instanceUnderTest.pollImmediately(from: dateThree)
        await instanceUnderTest.pollImmediately(from: dateFour)

        // Then - only first task should be present in map as cleanup was disabled for first invocation
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsCallCount, 4)
        await XCTAssertNil_async(await instanceUnderTest._testPollLatestLogsParametersAtIndex(0)?.date)
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsParametersAtIndex(1)?.date, dateTwo)
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsParametersAtIndex(2)?.date, dateThree)
        await XCTAssertEqual_async(await instanceUnderTest._testPollLatestLogsParametersAtIndex(3)?.date, dateFour)
    }

    // MARK: - Execute Polling

    func test_executePoll_completion_willReExecutePoll() async throws {
        // Given
        await instanceUnderTest.startPolling()

        // When
        await instanceUnderTest.executePoll() // Initial poll
        let taskOne = try await XCTUnwrap_async(await instanceUnderTest.pendingPollTask)
        _ = await instanceUnderTest.pendingPollTask?.result
        let taskTwo = try await XCTUnwrap_async(await instanceUnderTest.pendingPollTask)
        _ = await instanceUnderTest.pendingPollTask?.result // Second poll
        let taskThree = try await XCTUnwrap_async(await instanceUnderTest.pendingPollTask)
        _ = await instanceUnderTest.pendingPollTask?.result // Third poll

        // Then
        XCTAssertNotEqual(taskOne, taskTwo)
        XCTAssertNotEqual(taskTwo, taskThree)
    }

    func test_executePoll_pollingDisabled_willNotExecutePoll() async {
        // Given
        await instanceUnderTest.stopPolling()

        // When
        await instanceUnderTest.executePoll()

        // Then
        await XCTAssertNil_async(await instanceUnderTest.pendingPollTask)
    }
}
