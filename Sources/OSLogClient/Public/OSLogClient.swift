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

    /// Internal polling timer used to invoke `OSLogStore` lookups.
    public static var pollingInterval: PollingInterval {
        get {
            client.pollingInterval
        }
        set {
            client.pollingInterval = newValue
        }
    }

    /// Returns `false` when the ``OSLogClient/initialize(pollingInterval:logStore:)`` method **has not been invoked**
    public static var isInitialized: Bool {
        _client != nil
    }

    /// Will return `true` when the client is actively polling for logs.
    ///
    /// You can start/stop polling by invoking the ``OSLogClient/startPolling()`` and ``OSLogClient/stopPolling()`` methods.
    public static var isPolling: Bool {
        client.isPollingEnabled
    }

    /// Will start polling logs at the assigned interval.
    public static func startPolling() {
        client.startPolling()
    }

    /// Will stop polling logs.
    public static func stopPolling() {
        client.stopPolling()
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instance.
    /// - Parameter driver: The driver to register
    public static func registerDriver(_ driver: LogDriver) {
        Task.detached(priority: .userInitiated) {
            await client.registerDriver(driver)
        }
    }

    /// Will register the given array of driver instances to receive any polled logs.
    ///
    /// **Note:** The client will hold a strong reference to the driver instances.
    /// - Parameter drivers: Array of ``LogDriver`` instances.
    public static func registerDrivers(_ drivers: [LogDriver]) {
        drivers.forEach(registerDriver(_:))
    }

    /// Will deregister the driver with the given identifier from receiving an logs.
    /// - Parameter id: The id of the driver to deregister.
    public static func deregisterDriver(withId id: String) {
        Task.detached(priority: .userInitiated) {
            await client.deregisterDriver(withId: id)
        }
    }
}
