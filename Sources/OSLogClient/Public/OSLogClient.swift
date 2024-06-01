//
//  OSLogClient.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
@_exported import OSLog

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
public final class OSLogClient {

    // MARK: - Internal
    
    /// Internal shared client instance.
    static var _client: LogClient?
    
    /// Convenience getter for non-optional client instance. If the underlying `_client` instance is `nil` then a fatal error will occur.
    static var client: LogClient {
        guard let instance = _client else {
            fatalError("Error: `OSLogClient` not initialized. Please run `OSLogClient.initialize()` before use.")
        }
        return instance
    }

    // MARK: - Public

    /// Will initialize and configure the client to poll and broadcast logs to registered drivers.
    /// - Parameter logStore: Optional ``OSLogStore`` instance to poll. Default is assigned based on ``OSLogStore/Scope/currentProcessIdentifier``
    public static func initialize(pollingInterval: PollingInterval = .medium, logStore: OSLogStore? = nil) throws {
        guard _client == nil else {
            throw OSLogClientError.clientAlreadyInitialized
        }
        do {
            _client = try LogClient(pollingInterval: pollingInterval, logStore: logStore)
        } catch {
            throw OSLogClientError.unableToLoadLogStore(error: error.localizedDescription)
        }
    }

    /// The current polling interval.
    /// - See: ``PollingInterval``
    public static var pollingInterval: PollingInterval {
        get async {
            await client.pollingInterval
        }
    }

    /// Bool whether polling is currently active or not.
    public static var isPolling: Bool {
        get async {
            await client.isPollingEnabled
        }
    }

    /// Bool flag indicating whether polling should cease if there are no registered drivers.
    ///
    /// - Note: The inverse also applies, in that if drivers are registered polling will start again
    /// if the ``OSLogClient/isPollingEnabled`` flag is `true`.
    /// - Note: Default is `true`
    public static var shouldPauseIfNoRegisteredDrivers: Bool {
        get async {
            await client.shouldPauseIfNoRegisteredDrivers
        }
    }

    /// The most recent date-time of a processed/polled log.
    public static var lastPolledDate: Date? {
        get async {
            await client.lastPolledDate
        }
    }

    /// Returns `false` when the ``OSLogClient/initialize(pollingInterval:logStore:)`` method **has not been invoked**
    public static var isInitialized: Bool {
        _client != nil
    }

    // MARK: - Helpers

    /// Will start polling logs at the assigned interval.
    public static func startPolling() async {
        await client.startPolling()
    }

    /// Will stop polling logs.
    public static func stopPolling() async {
        await client.stopPolling()
    }
    
    /// Will update the time between polls to the given interval.
    ///
    /// **Note:** If a poll is currently in-progress the interval will be applied once completed.
    /// - Parameter interval: The interval to poll at.
    /// - SeeAlso: ``PollingInterval``
    public static func setPollingInterval(_ interval: PollingInterval) async {
        await client.setPollingInterval(interval)
    }

    /// Will force an immediate poll of logs on a detached task. The same log processing and broadcasting to drivers will
    /// occur as per the interval based polling.
    ///
    /// **Note:** This does not reset, delay, or otherwise alter the current polling interval (or scheduled tasks)
    /// - Parameter date: Optional date to query from. Leave `nil` to query from the last time logs were polled (default behaviour).
    public static func pollImmediately(from date: Date? = nil) {
        client.forcePoll(from: date)
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register
    public static func registerDriver(_ driver: LogDriver) async {
        await client.registerDriver(driver)
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
        await client.deregisterDriver(withId: id)
    }

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    public static func isDriverRegistered(withId id: String) async -> Bool {
        await client.isDriverRegistered(withId: id)
    }

    /// Will assign the given Bool flag to the ``OSLogClient/shouldPauseIfNoRegisteredDrivers`` property.
    ///
    /// - Note: When `true` if all drivers are deregistered, polling will cease until valid drivers are registered again.
    /// - Parameter flag: Bool whether enabled.
    public static func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) async {
        await client.setShouldPauseIfNoRegisteredDrivers(flag)
    }
}
