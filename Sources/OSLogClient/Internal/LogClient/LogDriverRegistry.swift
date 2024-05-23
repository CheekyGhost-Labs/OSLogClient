//
//  File.swift
//  
//
//  Created by Michael O'Brien on 23/5/2024.
//

import Foundation

/// Actor instance that maintains an array of registered drivers.
///
/// It provides a means to add, remove, and check the registration status of a driver.
actor LogDriverRegistry {

    // MARK: - Properties

    /// Array of subscribed drivers.
    private(set) var drivers: [LogDriver] = []

    /// Logger instance for any console output.
    private(set) var logger: Logger

    // MARK: - Lifecycle

    /// Will initialize a new poller instance with the given props.
    /// - Parameters:
    ///   - logStore: The ``OSLogStore`` instance to poll
    ///   - logger: Logger instance for any console output
    init(logger: Logger) {
        self.logger = logger
    }

    // MARK: - Helpers

    /// Indicates whether a driver with a specified identifier is registered.
    /// - Parameter id: The id of the driver.
    /// - Returns: A `Bool` indicating whether the a driver with the specified identifier is registered.
    func isDriverRegistered(withId id: String) -> Bool {
        drivers.contains(where: { $0.id == id })
    }

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// - Parameter driver: The driver to register
    func registerDriver(_ driver: LogDriver) {
        guard !isDriverRegistered(withId: driver.id) else {
            logger.error("Driver instance with id `\(driver.id)` is already registered; consider checking whether a driver is already registered by invoking `LogPoller.isDriverRegistered(withId:)` before invoking `LogPoller.registerDriver(_:)`.")
            return
        }
        drivers.append(driver)
    }

    /// Will deregister the driver with the given identifier from receiving an logs.
    /// - Parameter id: The id of the driver to deregister.
    func deregisterDriver(withId id: String) {
        drivers.removeAll(where: { $0.id == id })
    }
}
