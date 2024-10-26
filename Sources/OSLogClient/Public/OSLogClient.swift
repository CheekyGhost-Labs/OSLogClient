//
//  OSLogClient.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
@_exported @preconcurrency import OSLog

/// Class that provides configurable polling of an `OSLogStore`.
/// Valid log items will be sent to any registered ``LogDriver`` instances.
///
/// Example usage:
/// ```swift
/// try OSLogClient.initialize(pollingInterval: .short)
/// OSLogClient.registerDriver(driverSubclass)
/// OSLogClient.startPolling()
/// ```
///
/// - You must initialize the utility using the ``OSLogClient/initialize(pollingInterval:logStore:)`` method **before use**. Failure
/// to do this will result in a fatal error being thrown.
///
/// - You can register ``LogDriver`` instances via the ``OSLogClient/registerDriver(_:)`` method.
///
/// - By default polling will not automatically start, once you have finished setting up and registering drivers, you can start and stop
/// polling by using the ``OSLogClient/startPolling()`` and ``OSLogClient/stopPolling()`` methods.
///

public actor OSLogClient {

    // MARK: - Internal

    /// Internal shared client instance.
    static let _client: OSLogClient = OSLogClient(logClient: nil)

    /// Convenience getter for non-optional client instance. If the underlying `_client` instance is `nil` then a fatal error will occur.
    var logClient: LogClient {
        guard let instance = _logClient else {
            fatalError("Error: `OSLogClient` not initialized. Please run `OSLogClient.initialize()` before use.")
        }
        return instance
    }

    /// The underlying log client belonging to the shared instance.
    /// Note: This is marked as `nonisolated(unsafe)` to avoid an error when getting the immutable `pollingInterval`.
    /// The instance is used correctly within the OSLogClient setup.
    var _logClient: LogClient?

    // MARK: - Lifecycle

    init(logClient: LogClient?) {
        self._logClient = logClient
    }

    // MARK: - Public

    /// Will initialize and configure the client to poll and broadcast logs to registered drivers.
    /// - Parameter logStore: Optional ``OSLogStore`` instance to poll. Default is assigned based on ``OSLogStore/Scope/currentProcessIdentifier``
    public static func initialize(
        pollingInterval: PollingInterval = .medium,
        lastProcessedStrategy: LastProcessedStrategy = .default,
        logStore: OSLogStore? = nil
    ) async throws {
        guard await _client._logClient == nil else {
            throw OSLogClientError.clientAlreadyInitialized
        }
        do {
            let logStore = try logStore ?? OSLogStore(scope: .currentProcessIdentifier)
            let logClient = LogClient(pollingInterval: pollingInterval, lastProcessedStrategy: lastProcessedStrategy, logStore: logStore)
            await _client.setLogClient(logClient)
        } catch {
            throw OSLogClientError.unableToLoadLogStore(error: error.localizedDescription)
        }
    }

    // MARK: - Internal
    
    /// Internal helper to facilitate isolated mutations and unit testing.
    /// - Parameter client: The client instance to assign.
    func setLogClient(_ client: LogClient?) async {
        _logClient = client
    }

    // MARK: - Getters: Immutable Configs

    /// The current polling interval.
    /// - See: ``PollingInterval``
    public static var pollingInterval: PollingInterval {
        get async {
            await _client.logClient.pollingInterval
        }
    }

    /// The strategy being used when loading, updating, and working with the last processed date.
    /// - See: ``LastProcessedStrategy``
    public static var lastProcessedStrategy: any LastProcessedStrategy {
        get async {
            await _client.logClient.lastProcessedStrategy
        }
    }

    // MARK: - Getters: Mutable Settings

    /// Bool whether polling is currently enabled or not.
    public static var isEnabled: Bool {
        get async {
            await _client.logClient.isEnabled
        }
    }

    /// Bool flag indicating whether polling should cease if there are no registered drivers.
    ///
    /// - Note: The inverse also applies, in that if drivers are registered polling will start again
    /// if the ``OSLogClient/isEnabled`` flag is `true`.
    /// - Note: Default is `true`
    public static var shouldPauseIfNoRegisteredDrivers: Bool {
        get async {
            await _client.logClient.shouldPauseIfNoRegisteredDrivers
        }
    }

    /// The most recent date-time that the log store was successfully queried and processed.
    public static var lastProcessedDate: Date? {
        get async {
            await _client.logClient.lastProcessedDate
        }
    }

    // MARK: - Helpers Convenience

    /// Returns `false` when the ``OSLogClient/initialize(pollingInterval:logStore:)`` method **has not been invoked**
    public static var isInitialized: Bool {
        get async {
            await _client._logClient != nil
        }
    }

    // MARK: - Helpers: Polling

    /// Will start polling logs at the assigned interval.
    public static func startPolling() async {
        await _client.logClient.startPolling()
    }

    /// Will stop polling logs.
    public static func stopPolling() async {
        await _client.logClient.stopPolling()
    }

    /// Will update the time between polls to the given interval.
    ///
    /// - Note: If a poll is currently in-progress the interval will be applied once completed. This will
    /// re-build the shared convenience client as the ``LogClient/pollingInterval`` is immutable.
    ///
    /// - Parameter interval: The interval to poll at.
    /// - SeeAlso: ``PollingInterval``
    public static func setPollingInterval(_ interval: PollingInterval) async {
        // Resolve current settings
        let currentIsEnabled = await _client.logClient.isEnabled
        // Build new client instance
        let newLogClient = await LogClient(
            pollingInterval: interval,
            drivers: _client.logClient.drivers,
            lastProcessedStrategy: _client.logClient.lastProcessedStrategy,
            logStore: _client.logClient.logStore,
            logger: _client.logClient.logger,
            processInfoEnvironmentProvider: _client.logClient.processInfoEnvironmentProvider
        )
        // Assign non-isolated
        await newLogClient.setShouldPauseIfNoRegisteredDrivers(_client.logClient.shouldPauseIfNoRegisteredDrivers)
        await _client.setLogClient(newLogClient)
        // Enable if was enabled previously
        if currentIsEnabled {
            await newLogClient.startPolling()
        }
    }

    /// Will force an immediate poll of logs on a detached task. The same log processing and broadcasting to drivers will
    /// occur as per the interval based polling.
    ///
    /// **Note:** This does not reset, delay, or otherwise alter the current polling interval (or scheduled tasks)
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    public static func pollImmediately(from date: Date? = nil) async {
        await _client.logClient.pollLatestLogs(from: date)
    }

    // MARK: - Helpers: Drivers

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register
    public static func registerDriver(_ driver: LogDriver) async {
        await _client.logClient.registerDriver(driver)
    }

    /// Will register the given array of driver instances to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instances.
    /// - Parameter drivers: Array of ``LogDriver`` instances.
    public static func registerDrivers(_ drivers: [LogDriver]) async {
        for driver in drivers {
            await registerDriver(driver)
        }
    }

    /// Will deregister the driver with the given identifier from receiving an logs.
    /// - Parameter id: The id of the driver to deregister.
    public static func deregisterDriver(withId id: String) async {
        await _client.logClient.deregisterDriver(withId: id)
    }

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    public static func isDriverRegistered(withId id: String) async -> Bool {
        await _client.logClient.isDriverRegistered(withId: id)
    }

    /// Will assign the given Bool flag to the ``OSLogClient/shouldPauseIfNoRegisteredDrivers`` property.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Parameter flag: Bool whether enabled.
    public static func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) async {
        await _client.logClient.setShouldPauseIfNoRegisteredDrivers(flag)
    }

    // MARK: - Deprecated

    /// The most recent date-time of a processed/polled log.
    @available(*, deprecated, renamed: "lastProcessedDate", message: "`lastPolledDate` was an inaccurate name. Please use `lastProcessedDate`")
    public static var lastPolledDate: Date? {
        get async {
            await _client.logClient.lastProcessedDate
        }
    }

    /// Bool whether polling is currently active or not.
    @available(*, deprecated, renamed: "isEnabled", message: "`isPolling` has been renamed. Please use `isEnabled` insread")
    public static var isPolling: Bool {
        get async {
            await _client.logClient.isEnabled
        }
    }
}
