//
//  LogDriverRegistryTests.swift
//  
//
//  Created by Michael O'Brien on 24/5/2024.
//

import XCTest
@testable import OSLogClient

final class LogDriverRegistryTests: XCTestCase {

    // MARK: - Properties

    let logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "unit-tests")
    var logDriverSpy: LogDriverSpy!
    var logDriverSpyTwo: LogDriverSpy!
    var instanceUnderTest: LogDriverRegistry!

    override func setUpWithError() throws {
        logDriverSpy = LogDriverSpy(id: "test")
        logDriverSpyTwo = LogDriverSpy(id: "test-two")
        instanceUnderTest = LogDriverRegistry(logger: logger)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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
}
