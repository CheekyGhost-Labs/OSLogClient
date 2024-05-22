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
class LogClient {

    // MARK: - Properties

    /// Internal logger for any console output.
    var logger: Logger = Logger(subsystem: "com.cheekyghost.OSLogClient", category: "client")

    /// The current polling interval. Defaults to ``PollingInterval/medium``
    /// - See: ``PollingInterval``
    var pollingInterval: PollingInterval {
        didSet {
            pendingPollTask?.cancel()
            if isPollingEnabled {
                executePoll()
            }
        }
    }

    /// ``LogPoller`` instance for maintaining drivers and polling/processing logs.
    var logPoller: LogPoller

    /// Transient task assigned when the `executePoll` is called.
    /// This is managed so it can be cancelled if needed.
    var pendingPollTask: Task<(), Error>?

    /// Bool whether polling is currently active or not.
    var isPollingEnabled: Bool = false

    /// Mapping of unique id's to a transient tasks created when the `forcePoll` is called.
    /// These are managed for unit testing and potential future contexts (invalidation, cancelling etc)
    /// A task is removed once it has completed.
    var immediatePollTaskMap: [UUID: Task<(), Error>] = [:]

    // MARK: - Lifecycle

    required init(pollingInterval: PollingInterval = .medium, logStore: OSLogStore? = nil) throws {
        let store = try (logStore ?? OSLogStore(scope: .currentProcessIdentifier))
        self.logPoller = LogPoller(logStore: store, logger: logger)
        self.pollingInterval = pollingInterval
    }

    deinit {
        pendingPollTask?.cancel()
        immediatePollTaskMap.forEach { $0.value.cancel() }
    }

    // MARK: - Helpers: Internal

    /// Will enable the ``OSLogClient/isPollingEnabled`` flag and invoke the ``OSLogClient/executePoll()`` method.
    func startPolling() {
        isPollingEnabled = true
        executePoll()
    }

    /// Will disable the ``OSLogClient/isPollingEnabled`` flag and cancel the ``OSLogClient/pendingPollTask`` if assigned.
    func stopPolling() {
        isPollingEnabled = false
        pendingPollTask?.cancel()
        pendingPollTask = nil
    }

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    func isDriverRegistered(withId id: String) async -> Bool {
        await logPoller.isDriverRegistered(withId: id)
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register.
    func registerDriver(_ driver: LogDriver) async {
        await logPoller.registerDriver(driver)
        // If polling is enabled, but no pending task due to previously empty drivers, can start the polling up again
        if isPollingEnabled, pendingPollTask == nil {
            executePoll()
        }
    }

    /// Will deregister the driver with the given identifier from receiving any logs.
    /// - Parameter id: The id of the driver to deregister.
    func deregisterDriver(withId id: String) async {
        await logPoller.deregisterDriver(withId: id)
        if await logPoller.drivers.isEmpty {
            pendingPollTask?.cancel()
            pendingPollTask = nil
        }
    }

    /// Will force an immediate poll of logs on a detached task.
    /// **Note:** This does not reset or otherwise alter the current interval driven polling.
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    func forcePoll(from date: Date? = nil) {
        // Generate task
        let taskId: UUID = .init()
        let pollTask: Task<(), Error> = Task.detached(priority: .userInitiated) { [weak self, taskId] in
            guard let self else { return }
            await self.logPoller.pollLatestLogs(from: date)
            self.immediatePollTaskMap.removeValue(forKey: taskId)
        }
        immediatePollTaskMap[taskId] = pollTask
    }

    /// Will execute the poll operation on the log poller instance.
    func executePoll() {
        guard isPollingEnabled else {
            pendingPollTask = nil
            return
        }
        pendingPollTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            try await Task.sleep(nanoseconds: self.pollingInterval.nanoseconds)
            await self.logPoller.pollLatestLogs()
            self.executePoll()
        }
    }
}
