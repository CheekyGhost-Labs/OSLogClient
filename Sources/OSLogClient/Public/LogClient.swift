//
//  LogClient.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import OSLog

/// Class that provides configurable polling of an `OSLogStore`.
/// Valid log items will be sent to any registered ``LogDriver`` instances.
public actor LogClient {

    // MARK: - Properties: Immutable

    /// The current polling interval. Defaults to ``PollingInterval/medium``.
    /// - See: ``PollingInterval``
    public let pollingInterval: PollingInterval

    /// The strategy to use when loading, updating, and working with the last processed date.
    /// - See: ``LastProcessedStrategy``
    internal(set) public var lastProcessedStrategy: any LastProcessedStrategy

    // MARK: - Properties: Settings

    /// Bool whether the poller is enabled.
    /// - Note: Please use the ``LogClient/startPolling()`` and ``LogClient/stopPolling()`` to alter this value.
    private(set) public var isEnabled: Bool = false

    /// Bool flag indicating whether polling should cease if there are no registered drivers.
    ///
    /// Can be updated using the ``LogClient/setShouldPauseIfNoRegisteredDrivers(_:)`` method.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Note: The inverse also applies, in that if drivers are registered polling will start again
    /// if the `isEnabled` flag is `true`.
    private(set) public var shouldPauseIfNoRegisteredDrivers: Bool = true

    /// The most recent date-time of a processed/polled log
    public var lastProcessedDate: Date? {
        lastProcessedStrategy.date
    }

    // MARK: - Properties: Drivers

    /// Array of subscribed drivers.
    private(set) public var drivers: [LogDriver] = []

    // MARK: - Properties: Internal

    /// ``OSLogStore`` instance to poll for logs in.
    let logStore: OSLogStore

    /// Internal logger for any console output.
    let logger: Logger

    /// A template predicate used while polling logs
    let datePredicate: NSPredicate = NSPredicate(format: "date > $DATE")

    // MARK: - Properties: Polling Tasks

    /// Transient task assigned when the `executePoll` is called.
    /// This is managed so it can be cancelled if needed.
    var pendingPollTask: Task<(), Error>?

    // MARK: - Lifecycle

    public init(
        pollingInterval: PollingInterval,
        lastProcessedStrategy: some LastProcessedStrategy,
        logStore: OSLogStore,
        logger: Logger? = nil
    ) {
        self.logStore = logStore
        self.pollingInterval = pollingInterval
        self.lastProcessedStrategy = lastProcessedStrategy
        self.logger = logger ?? Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")
        self.processInfoEnvironmentProvider = nil
    }

    /// Internal init used when re-building a client instance from the static `OSLogClient` convenience entry point.
    init(
        pollingInterval: PollingInterval,
        drivers: [LogDriver],
        lastProcessedStrategy: some LastProcessedStrategy,
        logStore: OSLogStore,
        logger: Logger? = nil,
        processInfoEnvironmentProvider: ProcessInfoEnvironmentProvider? = nil
    ) {
        self.logStore = logStore
        self.drivers = drivers
        self.pollingInterval = pollingInterval
        self.lastProcessedStrategy = lastProcessedStrategy
        self.logger = logger ?? Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")
        self.processInfoEnvironmentProvider = processInfoEnvironmentProvider
    }

    deinit {
        pendingPollTask?.cancel()
    }

    // MARK: - Helpers

    /// Will enable the ``OSLogClient/isPollingEnabled`` flag and invoke the ``OSLogClient/executePoll()`` method.
    public func startPolling() {
        isEnabled = true
        // Don't execute if no drivers registered
        if shouldPauseIfNoRegisteredDrivers, drivers.isEmpty {
            return
        }
        // Otherwise execute poll
        if pendingPollTask == nil {
            executePoll()
        }
    }

    /// Will disable the ``OSLogClient/isPollingEnabled`` flag and cancel the ``OSLogClient/pendingPollTask`` if assigned.
    public func stopPolling() {
        isEnabled = false
        pendingPollTask?.cancel()
        pendingPollTask = nil
    }

    // MARK: - Helpers

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    public func isDriverRegistered(withId id: String) -> Bool {
        drivers.contains(where: { $0.id == id })
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register.
    public func registerDriver(_ driver: LogDriver) {
        // Don't action if driver is already present
        guard !isDriverRegistered(withId: driver.id) else {
            logger.error("Driver instance with id `\(driver.id)` is already registered; consider checking whether a driver is already registered by invoking `LogPoller.isDriverRegistered(withId:)` before invoking `LogPoller.registerDriver(_:)`.")
            return
        }
        // Derive if currently no drivers registered
        let wasEmpty = drivers.isEmpty
        // Register driver
        drivers.append(driver)
        // If polling is enabled, but no pending task due to previously empty drivers, can start the polling up again
        if isEnabled, shouldPauseIfNoRegisteredDrivers, wasEmpty {
            executePoll()
        }
    }

    /// Will deregister the driver with the given identifier from receiving any logs.
    /// - Parameter id: The id of the driver to deregister.
    public func deregisterDriver(withId id: String) {
        drivers.removeAll(where: { $0.id == id })
        // If polling is enabled, but no pending task due to previously empty drivers, can start the polling up again
        if isEnabled, shouldPauseIfNoRegisteredDrivers, drivers.isEmpty {
            softStopPolling()
        }
    }
    
    /// Will assign the given Bool flag to the ``LogClient/shouldPauseIfNoRegisteredDrivers`` property.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Parameter flag: Bool whether enabled.
    public func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) {
        shouldPauseIfNoRegisteredDrivers = flag
    }

    // MARK: - Helpers: Polling

    /// Will force an immediate poll of logs.
    ///
    /// **Note:** This does not reset or otherwise alter the current interval driven polling.
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    public func pollImmediately(from date: Date? = nil) {
        pollLatestLogs(from: date)
    }

    /// Will cancel any pending poll tasks, but not assign the `isPollingEnabled` flag to false.
    /// This is called when all drivers are deregistered but the consumer has not explicitly stopped polling.
    func softStopPolling() {
        pendingPollTask?.cancel()
        pendingPollTask = nil
    }

    /// Will assess the given entry and ensure it is both a valid `OSLogEntryLog` instance.
    /// - Parameter entry: The entry to assess.
    /// - Returns: `OSLogEntryLog` or `nil`.
    func validateLogEntry(_ entry: OSLogEntry) -> OSLogEntryLog? {
        entry as? OSLogEntryLog
    }

    /// Will poll logs since the last processed time position and send to any registered drivers for validation and processing.
    /// - Parameter date: Optional date to request logs from. Leave this `nil` to default to the `lastProcessed` property.
    func pollLatestLogs(from date: Date? = nil) {
        // Unit test support
        _testTrackPollLatestLogs(date: date)
        do {
            var predicate: NSPredicate?
            let lastProcessed = lastProcessedDate
            if let fromDate = date ?? lastProcessed {
                predicate = datePredicate.withSubstitutionVariables(["DATE": fromDate])
            }
            let items = try logStore.getEntries(matching: predicate).compactMap(validateLogEntry)
            for driver in drivers {
                driver.processLogs(items)
            }
            // Update last processed
            var nextLastProcessed = lastProcessed
            if let lastItemDate = items.max(by: { $0.date <= $1.date })?.date {
                nextLastProcessed = lastItemDate
            }
            setLastProcessedDate(nextLastProcessed)
        } catch {
            logger.error("Error: Unable to get log entries from store: `\(error.localizedDescription)`")
        }
    }

    /// Will execute the poll operation on the log poller instance.
    func executePoll() {
        guard isEnabled else {
            pendingPollTask = nil
            return
        }
        pendingPollTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            try await Task.sleep(nanoseconds: self.pollingInterval.nanoseconds)
            try Task.checkCancellation()
            await self.pollLatestLogs()
            try Task.checkCancellation()
            await self.executePoll()
        }
    }
    
    /// Will assign the ``lastProcessedStrategy/date`` to the given value.
    func setLastProcessedDate(_ date: Date?) {
        lastProcessedStrategy.setLastProcessedDate(date)
    }

    // MARK: - Internal: Unit Testing Support

    /*
     Actors don't support convenience init. This internal init is used to inject a custom process info provider for facilitating
     some unit test scenarios.

     Did look at a protocol driven approach using the `: Actor` conformance, but would still not be able to subclass LogClient as
     it is an actor. Instead I have put these methods in along with an internal-only process info environment provider protocol to
     decorate various methods to facilitate unit testing where needed. Can tidy things up in future work.
     */

    /// Internal `ProcessInfoProvider` conforming instance used to facilitate some unit test scenarios
    let processInfoEnvironmentProvider: ProcessInfoEnvironmentProvider?

    init(
        pollingInterval: PollingInterval,
        lastProcessedStrategy: any LastProcessedStrategy,
        logStore: OSLogStore,
        logger: Logger? = nil,
        processInfoEnvironmentProvider: ProcessInfoEnvironmentProvider?
    ) {
        self.logStore = logStore
        self.pollingInterval = pollingInterval
        self.lastProcessedStrategy = lastProcessedStrategy
        self.logger = logger ?? Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")
        self.processInfoEnvironmentProvider = processInfoEnvironmentProvider
    }

    var isUnitTesting: Bool {
        guard let environment = processInfoEnvironmentProvider?.processInfoEnvironment else { return false }
        // Comparing both xcode-driven unit testing and custom injected environment argument.
        return environment["OSLOGCLIENT_UNIT_TESTING"] == "1"
    }

    /// Internal method to assign the pending poll task. This will only be actioned if being run within a unit-testing context.
    /// - Parameter task: The task to assign.
    func _testSetPendingPollTask(_ task: Task<(), Error>?) {
        guard isUnitTesting else { return }
        pendingPollTask = task
    }

    var _testPollLatestLogsCalled: Bool { _testPollLatestLogsCallCount > 0 }
    var _testPollLatestLogsCallCount: Int = 0
    var _testPollLatestLogsParameters: (date: Date?, Void)? { _testPollLatestLogsParameterList.last }
    var _testPollLatestLogsParameterList: [(date: Date?, Void)] = []

    func _testTrackPollLatestLogs(date: Date?) {
        guard isUnitTesting else { return }
        _testPollLatestLogsCallCount += 1
        _testPollLatestLogsParameterList.append((date, ()))
    }

    func _testPollLatestLogsParametersAtIndex(_ index: Int) async -> (date: Date?, Void)? {
        guard index < _testPollLatestLogsParameterList.count else { return nil }
        return _testPollLatestLogsParameterList[index]
    }
}
