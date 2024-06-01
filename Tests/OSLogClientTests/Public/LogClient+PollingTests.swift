//
//  LogClient+PollingTests.swift
//  
//
//  Created by Michael O'Brien on 2/6/2024.
//

import XCTest
@testable import OSLogClient

final class LogClientPollingTests: XCTestCase {

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
