//
//  LogClientPartialSpy.swift
//  
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
@testable import OSLogClient

class LogClientPartialSpy: LogClient {

    var executePollCalled: Bool { executePollCallCount > 0 }
    var executePollCallCount: Int = 0
    var executePollShouldForwardToSuper: Bool = false

    override func executePoll() {
        executePollCallCount += 1
        if executePollShouldForwardToSuper {
            super.executePoll()
        }
    }

    var forcePollCalled: Bool { forcePollCallCount > 0 }
    var forcePollCallCount: Int = 0
    var forcePollParameters: (date: Date?, Void)? { forcePollParameterList.last }
    var forcePollParameterList: [(date: Date?, Void)] = []
    var forcePollShouldForwardToSuper: Bool = false

    override func forcePoll(from date: Date? = nil) {
        forcePollCallCount += 1
        forcePollParameterList.append((date: date, ()))
        if forcePollShouldForwardToSuper {
            super.forcePoll(from: date)
        }
    }

    var registerDriverCalled: Bool { registerDriverCallCount > 0 }
    var registerDriverCallCount: Int = 0
    var registerDriverParameters: (driver: LogDriver, Void)? { registerDriverParameterList.last }
    var registerDriverParameterList: [(driver: LogDriver, Void)] = []
    var registerDriverShouldForwardToSuper: Bool = false

    override func registerDriver(_ driver: LogDriver) async {
        registerDriverCallCount += 1
        registerDriverParameterList.append((driver, ()))
        if registerDriverShouldForwardToSuper {
            await super.registerDriver(driver)
        }
    }

    var deregisterDriverCalled: Bool { deregisterDriverCallCount > 0 }
    var deregisterDriverCallCount: Int = 0
    var deregisterDriverParameters: (id: String, Void)? { deregisterDriverParameterList.last }
    var deregisterDriverParameterList: [(id: String, Void)] = []
    var deregisterDriverShouldForwardToSuper: Bool = false

    override func deregisterDriver(withId id: String) async {
        deregisterDriverCallCount += 1
        deregisterDriverParameterList.append((id, ()))
        if deregisterDriverShouldForwardToSuper {
            await super.deregisterDriver(withId: id)
        }
    }
}
