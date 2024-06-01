//
//  LogClientPartialSpy.swift
//
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
@testable import OSLogClient

//class LogClientPartialSpy: LogClient {
//
//    // Generated with Mimic
//
//    // MARK: - Spy: LogClientPartialSpy
//
//    convenience init() throws {
//        try! self.init(pollingInterval: .custom(1), logStore: nil)
//    }
//
//    var pollingIntervalSpy: VariableSpy<PollingInterval> = .init(.custom(1))
//
//    override var pollingInterval: PollingInterval {
//        get async {
//            pollingIntervalSpy.trackGetter()
//            if pollingIntervalSpy.isPartialGetter {
//                return await super.pollingInterval
//            }
//            return pollingIntervalSpy.stubbedResult
//        }
//    }
//
//    var isPollingEnabledSpy: VariableSpy<Bool> = .init(false)
//
//    override var isPollingEnabled: Bool {
//        get async {
//            isPollingEnabledSpy.trackGetter()
//            if isPollingEnabledSpy.isPartialGetter {
//                return await super.isPollingEnabled
//            }
//            return isPollingEnabledSpy.stubbedResult
//        }
//    }
//
//    var shouldPauseIfNoRegisteredDriversSpy: VariableSpy<Bool> = .init(false)
//
//    override var shouldPauseIfNoRegisteredDrivers: Bool {
//        get async {
//            shouldPauseIfNoRegisteredDriversSpy.trackGetter()
//            if shouldPauseIfNoRegisteredDriversSpy.isPartialGetter {
//                return await super.shouldPauseIfNoRegisteredDrivers
//            }
//            return shouldPauseIfNoRegisteredDriversSpy.stubbedResult
//        }
//    }
//
//    var lastPolledDateSpy: VariableSpy<Date?> = .init(nil)
//
//    override var lastPolledDate: Date? {
//        get async {
//            lastPolledDateSpy.trackGetter()
//            if lastPolledDateSpy.isPartialGetter {
//                return await super.lastPolledDate
//            }
//            return lastPolledDateSpy.stubbedResult
//        }
//    }
//
//    var pendingPollTaskSpy: VariableSpy<Task<(), Error>?> = .init(nil)
//
//    override var pendingPollTask: Task<(), Error>? {
//        get {
//            pendingPollTaskSpy.trackGetter()
//            if pendingPollTaskSpy.isPartialGetter {
//                return super.pendingPollTask
//            }
//            return pendingPollTaskSpy.stubbedResult
//        }
//        set {
//            pendingPollTaskSpy.trackSetter(newValue)
//            if pendingPollTaskSpy.isPartialSetter {
//                super.pendingPollTask = newValue
//            }
//        }
//    }
//
//    var immediatePollTaskMapSpy: VariableSpy<[UUID: Task<(), Error>]> = .init([:])
//
//    override var immediatePollTaskMap: [UUID: Task<(), Error>] {
//        get {
//            immediatePollTaskMapSpy.trackGetter()
//            if immediatePollTaskMapSpy.isPartialGetter {
//                return super.immediatePollTaskMap
//            }
//            return immediatePollTaskMapSpy.stubbedResult
//        }
//        set {
//            immediatePollTaskMapSpy.trackSetter(newValue)
//            if immediatePollTaskMapSpy.isPartialSetter {
//                super.immediatePollTaskMap = newValue
//            }
//        }
//    }
//
//    var startPollingSpy: FunctionSpy<Void, Void> = .init(())
//
//    override func startPolling() async {
//        startPollingSpy.track(())
//        if startPollingSpy.isPartialEnabled {
//            return await super.startPolling()
//        }
//    }
//
//    var stopPollingSpy: FunctionSpy<Void, Void> = .init(())
//
//    override func stopPolling() async {
//        stopPollingSpy.track(())
//        if stopPollingSpy.isPartialEnabled {
//            return await super.stopPolling()
//        }
//    }
//
//    var setPollingIntervalSpy_withInterval: FunctionSpy<(interval: PollingInterval, Void), Void> = .init(())
//
//    override func setPollingInterval(_ interval: PollingInterval) async {
//        setPollingIntervalSpy_withInterval.track((interval, ()))
//        if setPollingIntervalSpy_withInterval.isPartialEnabled {
//            return await super.setPollingInterval(interval)
//        }
//    }
//
//    var isDriverRegisteredSpy_withId_boolOut: FunctionSpy<(id: String, Void), Bool> = .init(false)
//
//    override func isDriverRegistered(withId id: String) async -> Bool {
//        isDriverRegisteredSpy_withId_boolOut.track((id, ()))
//        if isDriverRegisteredSpy_withId_boolOut.isPartialEnabled {
//            return await super.isDriverRegistered(withId: id)
//        }
//        return isDriverRegisteredSpy_withId_boolOut.stubbedOutput
//    }
//
//    var registerDriverSpy_withDriver: FunctionSpy<(driver: LogDriver, Void), Void> = .init(())
//
//    override func registerDriver(_ driver: LogDriver) async {
//        registerDriverSpy_withDriver.track((driver, ()))
//        if registerDriverSpy_withDriver.isPartialEnabled {
//            return await super.registerDriver(driver)
//        }
//    }
//
//    var deregisterDriverSpy_withId: FunctionSpy<(id: String, Void), Void> = .init(())
//
//    override func deregisterDriver(withId id: String) async {
//        deregisterDriverSpy_withId.track((id, ()))
//        if deregisterDriverSpy_withId.isPartialEnabled {
//            return await super.deregisterDriver(withId: id)
//        }
//    }
//
//    var forcePollSpy_withDate: FunctionSpy<(date: Date?, Void), Void> = .init(())
//
//    override func forcePoll(from date: Date? = nil) {
//        forcePollSpy_withDate.track((date, ()))
//        if forcePollSpy_withDate.isPartialEnabled {
//            return super.forcePoll(from: date)
//        }
//    }
//
//    var setShouldPauseIfNoRegisteredDriversSpy_withFlag: FunctionSpy<(flag: Bool, Void), Void> = .init(())
//
//    override func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) async {
//        setShouldPauseIfNoRegisteredDriversSpy_withFlag.track((flag, ()))
//        if setShouldPauseIfNoRegisteredDriversSpy_withFlag.isPartialEnabled {
//            await super.setShouldPauseIfNoRegisteredDrivers(flag)
//        }
//    }
//
//    var softStopPollingSpy: FunctionSpy<Void, Void> = .init(())
//
//    override func softStopPolling() {
//        softStopPollingSpy.track(())
//        if softStopPollingSpy.isPartialEnabled {
//            super.softStopPolling()
//        }
//    }
//
//    var validateLogEntrySpy_withEntry_oSLogEntryLogOptOut: FunctionSpy<(entry: OSLogEntry, Void), OSLogEntryLog?> = .init(nil)
//
//    override func validateLogEntry(_ entry: OSLogEntry) -> OSLogEntryLog? {
//        validateLogEntrySpy_withEntry_oSLogEntryLogOptOut.track((entry, ()))
//        if validateLogEntrySpy_withEntry_oSLogEntryLogOptOut.isPartialEnabled {
//            return super.validateLogEntry(entry)
//        }
//        return validateLogEntrySpy_withEntry_oSLogEntryLogOptOut.stubbedOutput
//    }
//
//    var pollLatestLogsSpy_withDate: FunctionSpy<(date: Date?, Void), Void> = .init(())
//
//    override func pollLatestLogs(from date: Date? = nil) async {
//        pollLatestLogsSpy_withDate.track((date, ()))
//        if pollLatestLogsSpy_withDate.isPartialEnabled {
//            return await super.pollLatestLogs(from: date)
//        }
//    }
//
//    var executePollSpy: FunctionSpy<Void, Void> = .init(())
//
//    override func executePoll() async {
//        executePollSpy.track(())
//        if executePollSpy.isPartialEnabled {
//            return await super.executePoll()
//        }
//    }
//
//    // MARK: - Mimic Helpers: Function
//
//    /// Convenience class for facilitating spy functionality on a `Function`.
//    final class FunctionSpy<Parameters, Output> {
//
//        // MARK: - Properties
//
//        /// Bool whether the associated function has been invoked
//        var called: Bool { callCount > 0 }
//
//        /// The total number of times the associated function has been invoked.
//        private(set) var callCount: Int = 0
//
//        /// The most recently tracked parameter set.
//        var recentParameters: Parameters? { parameterList.last }
//
//        /// List of parameter sets appended when the associated function is invoked.
//        private(set) var parameterList: [Parameters] = []
//
//        /// The function output kind. Default is `.none`
//        var stubbedOutput: Output
//
//        /// Bool whether the spy is for a partial spy strategy.
//        /// Default is `false`
//        var isPartialEnabled: Bool = false
//
//        /// Optional error to assign for throwing functions.
//        var error: Error?
//
//        /// Will track an invocation with the given parameters.
//        /// - Parameter parameters: The parameter set invoked with the function
//        func track(_ parameters: Parameters) {
//            callCount += 1
//            parameterList.append(parameters)
//        }
//
//        init(_ stubbedOutput: Output) { self.stubbedOutput = stubbedOutput }
//
//        /// Will reset any call counts and parameter sets
//        func reset() {
//            callCount = 0
//            parameterList = []
//            error = nil
//        }
//    }
//
//    // MARK: - Mimic Helpers: Variable
//
//    /// Convenience class for facilitating spy functionality on a `Variable`.
//    final class VariableSpy<DeclType> {
//
//        enum PartialType {
//            /// No super invocations or results will be used.
//            case disabled
//            /// The super value will be returned.
//            case getter
//            /// The super value will be updated to the incoming `newValue`.
//            case setter
//            /// The super value will be returned for the getter and the super value updated when using the setter.
//            case all
//        }
//
//        // Properties: Getter
//
//        /// Bool whether the associated getter accessor has been invoked
//        var getterCalled: Bool { getterCallCount > 0 }
//
//        /// The total number of times the getter accessor has been invoked.
//        private(set) var getterCallCount: Int = 0
//
//        /// Optional error to throw when accessing the getter. Only applies if the getter is throwing.
//        var getterError: Error?
//
//        /// The stubbed getter output value.
//        var stubbedResult: DeclType
//
//        // Properties: Setter
//
//        /// Bool whether the associated setter accessor has been invoked
//        var setterCalled: Bool { setterCallCount > 0 }
//
//        /// The total number of times the setter accessor has been invoked.
//        private(set) var setterCallCount: Int = 0
//
//        /// The most recently tracked parameter set.
//        var recentSetterParameters: DeclType? { setterParameterList.last }
//
//        /// List of parameter sets appended when the associated setter is invoked.
//        var setterParameterList: [DeclType] = []
//
//        // Properties: Spy
//
//        /// Partial type assessed by the generated mock outputs during invocations.
//        /// - See: ``PartialType``
//        var partialType: PartialType = .disabled
//
//        /// Returns true when the ``partialType`` is `.getter` or `.all`
//        var isPartialGetter: Bool { partialType == .getter || partialType == .all }
//
//        /// Returns true when the ``partialType`` is `.setter` or `.all`
//        var isPartialSetter: Bool { partialType == .setter || partialType == .all }
//
//        // Helpers
//
//        /// Will track a getter invocation.
//        func trackGetter() { getterCallCount += 1 }
//
//        /// Will track a setter invocation.
//        /// - Parameter parameter: The parameter sent to the setter.
//        func trackSetter(_ parameter: DeclType) {
//            setterCallCount += 1
//            setterParameterList.append(parameter)
//        }
//
//        init(_ stubbedResult: DeclType) { self.stubbedResult = stubbedResult }
//
//        /// Will reset any call counts and parameter sets
//        func reset() {
//            getterCallCount = 0
//            setterCallCount = 0
//            setterParameterList = []
//        }
//    }
//}
