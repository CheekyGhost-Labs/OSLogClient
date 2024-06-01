//
//  LogClient+DriverManagementTests.swift
//  
//
//  Created by Michael O'Brien on 2/6/2024.
//

import XCTest
@testable import OSLogClient

final class LogClientDriverManagementTests: XCTestCase {

    // MARK: - Properties

    let logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "unit-tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!
    var instanceUnderTest: LogClient!

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        let logStore = try OSLogStore(scope: .currentProcessIdentifier)
        logDriverSpy = LogDriverSpy(id: "test")
        logDriverSpyTwo = LogDriverSpy(id: "test-two")
        instanceUnderTest = LogClient(
            pollingInterval: .custom(1),
            lastProcessedStrategy: .default,
            logStore: logStore, 
            logger: logger,
            processInfoEnvironmentProvider: TestProcessInfoProvider()
        )
    }

    /**
     NOTE: Using direct assessment, and presence of expected objects (polling task etc) as unable to subclass (and therefore spy on)
     actor instances. This is annoying, but understandable due to the nature of an Actor.
     */

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
//
//    func test_deregisterDriver_driversRemaining_willNotInvokeSoftStopPolling() async {
//        // Given
//        await instanceUnderTest.registerDriver(logDriverSpy)
//        await instanceUnderTest.registerDriver(logDriverSpyTwo)
//        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)
//
//        // When
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
//
//        // Then
//        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 1)
//        XCTAssertFalse(instanceUnderTest.stopPollingSpy.called)
//    }
//
//    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingEnabled_willInvokeSoftStopPolling() async {
//        // Given
//        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
//        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = true
//        await instanceUnderTest.registerDriver(logDriverSpy)
//        await instanceUnderTest.registerDriver(logDriverSpyTwo)
//        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)
//
//        // When
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)
//
//        // Then
//        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
//        await XCTAssertEqual_async(instanceUnderTest.softStopPollingSpy.callCount, 1)
//    }
//
//    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversEnabled_pollingDisabled_willNotInvokeSoftStopPolling() async {
//        // Given
//        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
//        instanceUnderTest.isPollingEnabledSpy.stubbedResult = false
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = true
//        await instanceUnderTest.registerDriver(logDriverSpy)
//        await instanceUnderTest.registerDriver(logDriverSpyTwo)
//        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)
//
//        // When
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)
//
//        // Then
//        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
//        await XCTAssertFalse_async(instanceUnderTest.softStopPollingSpy.called)
//    }
//
//    func test_deregisterDriver_noDriversRemaining_shouldPauseIfNoRegisteredDriversDisabled_pollingEnabled_willNotInvokeSoftStopPolling() async {
//        // Given
//        instanceUnderTest.isPollingEnabledSpy.partialType = .disabled
//        instanceUnderTest.isPollingEnabledSpy.stubbedResult = true
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.partialType = .disabled
//        instanceUnderTest.shouldPauseIfNoRegisteredDriversSpy.stubbedResult = false
//        await instanceUnderTest.registerDriver(logDriverSpy)
//        await instanceUnderTest.registerDriver(logDriverSpyTwo)
//        await XCTAssertEqual_async(await instanceUnderTest.logDriverRegistry.drivers.count, 2)
//
//        // When
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpy.id)
//        await instanceUnderTest.deregisterDriver(withId: logDriverSpyTwo.id)
//
//        // Then
//        await XCTAssertTrue_async(await instanceUnderTest.logDriverRegistry.drivers.isEmpty)
//        await XCTAssertFalse_async(instanceUnderTest.softStopPollingSpy.called)
//    }
}
