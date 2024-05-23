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
public class LogClient {

    // MARK: - Properties: Public

    /// The current polling interval.
    /// - See: ``PollingInterval``
    public var pollingInterval: PollingInterval {
        get async {
            await config.pollingInterval
        }
    }

    /// Bool whether polling is currently active or not.
    public var isPollingEnabled: Bool {
        get async {
            await config.isEnabled
        }
    }

    /// Bool flag indicating whether polling should cease if there are no registered drivers.
    ///
    /// - Note: The inverse also applies, in that if drivers are registered polling will start again
    /// if the ``LogClient/isPollingEnabled`` flag is `true`.
    /// - Note: Default is `true`
    public var shouldPauseIfNoRegisteredDrivers: Bool {
        get async {
            await config.shouldPauseIfNoRegisteredDrivers
        }
    }

    /// The most recent date-time of a processed/polled log
    public var lastPolledDate: Date? {
        get async {
            await config.lastProcessed
        }
    }

    // MARK: - Properties: Internal

    /// ``OSLogStore`` instance to poll for logs in.
    let logStore: OSLogStore

    /// `PollingState` actor instance for holding polling configuration settings.
    let config: PollingConfiguration

    /// `LogDriverRegistry` actor instance for managing registered drivers.
    let logDriverRegistry: LogDriverRegistry

    /// Internal logger for any console output.
    let logger: Logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")

    /// A template predicate used while polling logs
    let datePredicate: NSPredicate = NSPredicate(format: "date > $DATE")

    /// Transient task assigned when the `executePoll` is called.
    /// This is managed so it can be cancelled if needed.
    var pendingPollTask: Task<(), Error>?

    /// Mapping of unique id's to a transient tasks created when the `forcePoll` is called.
    /// These are managed for unit testing and potential future contexts (invalidation, cancelling etc)
    /// A task is removed once it has completed.
    var immediatePollTaskMap: [UUID: Task<(), Error>] = [:]

    // MARK: - Lifecycle

    public required init(pollingInterval: PollingInterval = .medium, logStore: OSLogStore? = nil) throws {
        let store = try (logStore ?? OSLogStore(scope: .currentProcessIdentifier))
        self.logStore = store
        self.config = PollingConfiguration(isEnabled: false, pollingInterval: pollingInterval)
        self.logDriverRegistry = LogDriverRegistry(logger: logger)
    }

    deinit {
         pendingPollTask?.cancel()
         immediatePollTaskMap.forEach { $0.value.cancel() }
    }

    // MARK: - Helpers

    /// Will enable the ``OSLogClient/isPollingEnabled`` flag and invoke the ``OSLogClient/executePoll()`` method.
    public func startPolling() async {
        await config.setIsEnabled(true)
        if pendingPollTask == nil {
            await executePoll()
        }
    }

    /// Will disable the ``OSLogClient/isPollingEnabled`` flag and cancel the ``OSLogClient/pendingPollTask`` if assigned.
    public func stopPolling() async {
         await config.setIsEnabled(false)
         pendingPollTask?.cancel()
         pendingPollTask = nil
    }

    // MARK: - Helpers

    /// Will update the time between polls to the given interval.
    ///
    /// **Note:** If a poll is currently in-progress the interval will be applied once completed.
    /// - Parameter interval: The interval to poll at
    /// - SeeAlso: ``PollingInterval``
    public func setPollingInterval(_ interval: PollingInterval) async {
        pendingPollTask?.cancel()
        await config.setPollingInterval(interval)
        if await isPollingEnabled, await !logDriverRegistry.drivers.isEmpty {
            await executePoll()
        }
    }

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    public func isDriverRegistered(withId id: String) async -> Bool {
        await logDriverRegistry.isDriverRegistered(withId: id)
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register.
    public func registerDriver(_ driver: LogDriver) async {
        let wasEmpty = await logDriverRegistry.drivers.isEmpty
        await logDriverRegistry.registerDriver(driver)
        // If polling is enabled, but no pending task due to previously empty drivers, can start the polling up again
        if await isPollingEnabled, await shouldPauseIfNoRegisteredDrivers, wasEmpty {
            await executePoll()
        }
    }

    /// Will deregister the driver with the given identifier from receiving any logs.
    /// - Parameter id: The id of the driver to deregister.
    public func deregisterDriver(withId id: String) async {
        await logDriverRegistry.deregisterDriver(withId: id)
        // If polling is enabled, but no pending task due to previously empty drivers, can start the polling up again
        if await isPollingEnabled, await shouldPauseIfNoRegisteredDrivers, await logDriverRegistry.drivers.isEmpty {
            softStopPolling()
        }
    }

    /// Will force an immediate poll of logs on a detached task.
    /// **Note:** This does not reset or otherwise alter the current interval driven polling.
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    public func forcePoll(from date: Date? = nil) {
        // Generate task
        let taskId: UUID = .init()
        let pollTask: Task<(), Error> = Task(priority: .userInitiated) { [weak self, taskId] in
            guard let self else { return }
            await self.pollLatestLogs(from: date)
            self.immediatePollTaskMap.removeValue(forKey: taskId)
        }
        immediatePollTaskMap[taskId] = pollTask
    }
    
    /// Will assign the given Bool flag to the ``LogClient/shouldPauseIfNoRegisteredDrivers`` property.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Parameter flag: Bool whether enabled.
    public func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) async {
        await config.setShouldPauseIfNoRegisteredDrivers(flag)
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
    /// - Returns: `OSLogEntryLog` or `nil`
    func validateLogEntry(_ entry: OSLogEntry) -> OSLogEntryLog? {
        entry as? OSLogEntryLog
    }

    /// Will poll logs since the last processed time position and send to any registered drivers for validation and processing.
    /// - Parameter date: Optional date to request logs from. Leave this `nil` to default to the `lastProcessed` property.
    func pollLatestLogs(from date: Date? = nil) async {
        do {
            var predicate: NSPredicate?
            let lastProcessed = await config.lastProcessed
            if let fromDate = date ?? lastProcessed {
                predicate = datePredicate.withSubstitutionVariables(["DATE": fromDate])
            }
            let items = try logStore.getEntries(matching: predicate).compactMap(validateLogEntry)
            let sortedItems = items.sorted(by: { $0.date <= $1.date })
            // Broadcast logs to drivers
            await sortedItems.asyncForEach { log in
                await logDriverRegistry.drivers.asyncForEach {
                    $0.processLogIfValid(log)
                }
            }
            let nextLastProcessed = sortedItems.last?.date ?? lastProcessed
            await config.setLastProcessed(nextLastProcessed)
        } catch {
            logger.error("Error: Unable to get log entries from store: `\(error.localizedDescription)`")
        }
    }

    // MARK: - Helpers: Internal

    /// Will execute the poll operation on the log poller instance.
    func executePoll() async {
        guard await isPollingEnabled else {
            pendingPollTask = nil
            return
        }
        pendingPollTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            try await Task.sleep(nanoseconds: self.pollingInterval.nanoseconds)
            await self.pollLatestLogs()
            await self.executePoll()
        }
    }
}
