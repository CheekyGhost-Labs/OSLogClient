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
    public let lastProcessedStrategy: LastProcessedStrategy

    // MARK: - Properties: Settings

    /// Bool whether the poller is enabled.
    public var isEnabled: Bool = false

    /// Bool flag indicating whether polling should cease if there are no registered drivers.
    ///
    /// - Note: The inverse also applies, in that if drivers are registered polling will start again
    /// if the `isEnabled` flag is `true`.
    public var shouldPauseIfNoRegisteredDrivers: Bool = true

    /// The most recent date-time of a processed/polled log
    private(set) public lazy var lastProcessedDate: Date? = loadLastProcessedDate()

    // MARK: - Properties: Drivers

    /// Array of subscribed drivers.
    private(set) public var drivers: [LogDriver] = []

    // MARK: - Properties: Internal

    /// ``OSLogStore`` instance to poll for logs in.
    let logStore: OSLogStore

    /// Internal logger for any console output.
    let logger: Logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")

    /// A template predicate used while polling logs
    let datePredicate: NSPredicate = NSPredicate(format: "date > $DATE")

    // MARK: - Properties: Polling Tasks

    /// Transient task assigned when the `executePoll` is called.
    /// This is managed so it can be cancelled if needed.
    var pendingPollTask: Task<(), Error>?

    /// Mapping of unique id's to a transient tasks created when the `forcePoll` is called.
    /// These are managed for unit testing and potential future contexts (invalidation, cancelling, etc.).
    /// A task is removed once it has completed.
    var immediatePollTaskMap: [UUID: Task<(), Error>] = [:]

    // MARK: - Lifecycle

    public init(
        pollingInterval: PollingInterval,
        lastProcessedStrategy: LastProcessedStrategy,
        logStore: OSLogStore
    ) {
        self.logStore = logStore
        self.pollingInterval = pollingInterval
        self.lastProcessedStrategy = lastProcessedStrategy
    }

    init(
        pollingInterval: PollingInterval,
        lastProcessedStrategy: LastProcessedStrategy,
        logStore: OSLogStore,
        isEnabled: Bool
    ) {
        self.logStore = logStore
        self.pollingInterval = pollingInterval
        self.lastProcessedStrategy = lastProcessedStrategy
        self.isEnabled = isEnabled
    }

    deinit {
        pendingPollTask?.cancel()
        for pair in immediatePollTaskMap {
            pair.value.cancel()
        }
    }

    // MARK: - Helpers

    /// Will enable the ``OSLogClient/isPollingEnabled`` flag and invoke the ``OSLogClient/executePoll()`` method.
    public func startPolling() {
        isEnabled = true
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

    /// Will force an immediate poll of logs on a detached task.
    /// **Note:** This does not reset or otherwise alter the current interval driven polling.
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    public func pollImmediately(from date: Date? = nil) {
        // Generate task
        let taskId: UUID = .init()
        let pollTask: Task<(), Error> = Task(priority: .userInitiated) { [weak self, taskId] in
            guard let self else { return }
            await self.pollLatestLogs(from: date)
            await self.removeImmediatePollTask(withId: taskId)
        }
        immediatePollTaskMap[taskId] = pollTask
    }
    
    /// Will assign the given Bool flag to the ``LogClient/shouldPauseIfNoRegisteredDrivers`` property.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Parameter flag: Bool whether enabled.
    public func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) {
        shouldPauseIfNoRegisteredDrivers = flag
    }

    // MARK: - Helpers: Polling Task Helpers
    
    /// Will remove the immediate polling task with the given taskID from the map.
    /// - Parameter taskId: The id of the task to remove
    func removeImmediatePollTask(withId taskId: UUID) {
        immediatePollTaskMap.removeValue(forKey: taskId)
    }

    // MARK: - Helpers: Polling
    
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
            updateLastProcessedForItems(items: items)
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

    // MARK: - Helpers: Last Processed Date
    
    /// Will assign the `lastProcessedDate` to the given value.
    ///
    /// - Note: This will also action any related operations to honour the assigned ``LogClient/lastProcessedStrategy``
    /// - Parameter date: The date to assign.
    public func setLastProcessedDate(_ date: Date?) {
        // Assessing only non-memory supported option for now
        if case LastProcessedStrategy.userDefaults(let defaultsKey) = lastProcessedStrategy {
            UserDefaults.standard.setValue(date?.timeIntervalSince1970, forKey: defaultsKey)
        }
        lastProcessedDate = date
    }

    /// Will assess the current `lastProcessedStrategy` and return the last known/stored date.
    /// - Returns: `Date` or `nil`
    func loadLastProcessedDate() -> Date? {
        switch lastProcessedStrategy {
        case .userDefaults(let defaultsKey):
            guard let timestamp = UserDefaults.standard.value(forKey: defaultsKey) as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        case .inMemory:
            return lastProcessedDate
        }
    }
    /// Will assess the current `lastProcessedStrategy` and update the stored date accordingly.
    /// - Parameter items: The recently polled items.
    func updateLastProcessedForItems(items: [OSLogEntryLog]) {
        var lastProcessed = lastProcessedDate
        if let lastItemDate = items.max(by: { $0.date <= $1.date })?.date {
            lastProcessed = lastItemDate
        }
        setLastProcessedDate(lastProcessed)
    }
}
