//
//  OSLogClientTests.swift
//  
//
//  Created by Michael O'Brien on 26/5/2024.
//

import XCTest
import OSLog
@testable import OSLogClient

final class OSLogClientTests: XCTestCase {

    let subsystem = "com.cheekyghost.OSLogClient.tests"
    let logCategory = "tests"
    var logClientSpy: LogClientPartialSpy!
    let logger: Logger = .init(subsystem: "com.cheekyghost.OSLogClient.tests", category: "tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!

    override func setUpWithError() throws {
        logClientSpy = try LogClientPartialSpy(pollingInterval: .custom(1), logStore: nil)
        logDriverSpy = LogDriverSpy(id: "unit-tests")
        logDriverSpyTwo = LogDriverSpy(id: "unit-tests-two")
        OSLogClient._client = logClientSpy
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        logClientSpy = nil
        logDriverSpy = nil
        logDriverSpyTwo = nil
    }

    // MARK: - Helpers

    func test_pollingIntervalGetter_willInvokeUnderlyingClient() async {
        _ = await OSLogClient.pollingInterval
        await XCTAssertEqual_async(logClientSpy.pollingIntervalSpy.getterCallCount, 1)
    }

    func test_isPolling_willInvokeUnderlyingClient() async {
        _ = await OSLogClient.isPolling
        await XCTAssertEqual_async(logClientSpy.isPollingEnabledSpy.getterCallCount, 1)
    }

    func test_setShouldPauseIfNoRegisteredDrivers_willInvokeUnderlyingClient() async {
        _ = await OSLogClient.shouldPauseIfNoRegisteredDrivers
        await XCTAssertEqual_async(logClientSpy.shouldPauseIfNoRegisteredDriversSpy.getterCallCount, 1)
    }

    func test_lastPolledDate_willInvokeUnderlyingClient() async {
        _ = await OSLogClient.lastPolledDate
        await XCTAssertEqual_async(logClientSpy.lastPolledDateSpy.getterCallCount, 1)
    }

    func test_isInitialized_validClient_willReturnTrue() {
        OSLogClient._client = logClientSpy
        XCTAssertTrue(OSLogClient.isInitialized)
    }

    func test_isInitialized_noClient_willReturnFalse() {
        OSLogClient._client = nil
        XCTAssertFalse(OSLogClient.isInitialized)
    }

    // MARK: - Tests: Helpers

    func test_startPolling_willInvokeClient() async {
        await OSLogClient.startPolling()
        await XCTAssertEqual_async(logClientSpy.startPollingSpy.callCount, 1)
    }

    func test_stopPolling_willInvokeClient() async {
        await OSLogClient.stopPolling()
        await XCTAssertEqual_async(logClientSpy.stopPollingSpy.callCount, 1)
    }

    func test_setPollingInterval_willInvokeClient() async {
        await OSLogClient.setPollingInterval(.custom(123))
        await XCTAssertEqual_async(logClientSpy.setPollingIntervalSpy_withInterval.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.setPollingIntervalSpy_withInterval.recentParameters?.interval, .custom(123))
    }

    func test_pollImmediately_willInvokeClientWithExpectedValues() async {
        OSLogClient.pollImmediately(from: nil)
        await XCTAssertEqual_async(logClientSpy.forcePollSpy_withDate.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.forcePollSpy_withDate.recentParameters?.date, nil)
        let date = Date()
        OSLogClient.pollImmediately(from: date)
        await XCTAssertEqual_async(logClientSpy.forcePollSpy_withDate.callCount, 2)
        await XCTAssertEqual_async(logClientSpy.forcePollSpy_withDate.recentParameters?.date?.timeIntervalSince1970, date.timeIntervalSince1970)
    }

    func test_registerDriver_willInvokeClientWithProvidedValue() async {
        await OSLogClient.registerDriver(logDriverSpy)
        await XCTAssertEqual_async(logClientSpy.registerDriverSpy_withDriver.callCount, 1)
        await XCTAssertTrue_async(logClientSpy.registerDriverSpy_withDriver.recentParameters?.driver === logDriverSpy)
    }

    func test_registerDrivers_willInvokeClientWithProvidedValues() async {
        await OSLogClient.registerDrivers([logDriverSpy, logDriverSpyTwo])
        await XCTAssertEqual_async(logClientSpy.registerDriverSpy_withDriver.callCount, 2)
        await XCTAssertTrue_async(logClientSpy.registerDriverSpy_withDriver.parameterList[0].driver === logDriverSpy)
        await XCTAssertTrue_async(logClientSpy.registerDriverSpy_withDriver.parameterList[1].driver === logDriverSpyTwo)
    }

    func test_deregisterDriver_willInvokeClientWithProvidedValues() async {
        await OSLogClient.deregisterDriver(withId: "test")
        await XCTAssertEqual_async(logClientSpy.deregisterDriverSpy_withId.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.deregisterDriverSpy_withId.recentParameters?.id, "test")
    }

    func test_isDriverRegistered_willInvokeClientWithProvidedValues() async {
        _ = await OSLogClient.isDriverRegistered(withId: "test")
        await XCTAssertEqual_async(logClientSpy.isDriverRegisteredSpy_withId_boolOut.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.isDriverRegisteredSpy_withId_boolOut.recentParameters?.id, "test")
    }

    func test_setShouldPauseIfNoRegisteredDrivers_true_willInvokeClientWithProvidedValue() async {
        _ = await OSLogClient.setShouldPauseIfNoRegisteredDrivers(true)
        await XCTAssertEqual_async(logClientSpy.setShouldPauseIfNoRegisteredDriversSpy_withFlag.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.setShouldPauseIfNoRegisteredDriversSpy_withFlag.recentParameters?.flag, true)
    }

    func test_setShouldPauseIfNoRegisteredDrivers_false_willInvokeClientWithProvidedValue() async {
        _ = await OSLogClient.setShouldPauseIfNoRegisteredDrivers(false)
        await XCTAssertEqual_async(logClientSpy.setShouldPauseIfNoRegisteredDriversSpy_withFlag.callCount, 1)
        await XCTAssertEqual_async(logClientSpy.setShouldPauseIfNoRegisteredDriversSpy_withFlag.recentParameters?.flag, false)
    }
}
