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

    /// The current polling interval
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

    // MARK: - Lifecycle

    init(pollingInterval: PollingInterval, logStore: OSLogStore? = nil) throws {
        let store = try (logStore ?? OSLogStore(scope: .currentProcessIdentifier))
        self.logPoller = LogPoller(logStore: store, logger: logger)
        self.pollingInterval = pollingInterval
    }

    deinit {
        pendingPollTask?.cancel()
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

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register
    func registerDriver(_ driver: LogDriver) async {
        await logPoller.registerDriver(driver)
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
