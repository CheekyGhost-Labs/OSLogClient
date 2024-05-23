//
//  LogClientPollingConfigurationTests.swift
//  
//
//  Created by Michael O'Brien on 24/5/2024.
//

import XCTest
@testable import OSLogClient

final class LogClientPollingConfigurationTests: XCTestCase {

    var instanceUnderTest: LogClient.PollingConfiguration!

    override func setUpWithError() throws {
        instanceUnderTest = .init(isEnabled: false, pollingInterval: .custom(5))
    }

    // MARK: - Tests

    func test_init_willAssignProvidedProperties() async throws {
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .custom(5))
    }
    
    func test_setIsEnabled_willAssignProvidedFlag() async {
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
        await instanceUnderTest.setIsEnabled(true)
        await XCTAssertTrue_async(await instanceUnderTest.isEnabled)
        await instanceUnderTest.setIsEnabled(false)
        await XCTAssertFalse_async(await instanceUnderTest.isEnabled)
    }

    func test_setPollingInterval_willAssignProvidedValue() async {
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .custom(5))
        await instanceUnderTest.setPollingInterval(.short)
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .short)
        await instanceUnderTest.setPollingInterval(.medium)
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .medium)
        await instanceUnderTest.setPollingInterval(.long)
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .long)
        await instanceUnderTest.setPollingInterval(.custom(7))
        await XCTAssertEqual_async(await instanceUnderTest.pollingInterval, .custom(7))
    }

    func test_setLastProcessed_willAssignProvidedValue() async {
        await instanceUnderTest.setLastProcessed(nil)
        await XCTAssertEqual_async(await instanceUnderTest.lastProcessed, nil)
        let date = Date().addingTimeInterval(3600)
        await instanceUnderTest.setLastProcessed(date)
        await XCTAssertEqual_async(await instanceUnderTest.lastProcessed?.timeIntervalSince1970, date.timeIntervalSince1970)
    }
}
