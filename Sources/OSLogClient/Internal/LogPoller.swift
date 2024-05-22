//
//  LogPoller.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import OSLog

actor LogPoller {

    // MARK: - Supplementary

    enum Constants {
        static let lastProcessedKey: String = "com.cheekyghost.axologl.lastProcessed"
    }

    // MARK: - Properties

    /// Array of subscribed drivers.
    private(set) var drivers: [LogDriver] = []

    /// ``OSLogStore`` instance to poll for logs in.
    private(set) var logStore: OSLogStore

    /// Logger instance for any console output.
    private(set) var logger: Logger
    
    /// A template predicate used while polling logs
    private var datePredicate: NSPredicate?

    // MARK: - Properties: Computed
    
    /// The most recent date-time of a processed/polled log
    var lastProcessed: Date? {
        get {
            guard let timestamp = UserDefaults.standard.value(forKey: Constants.lastProcessedKey) as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: timestamp)
        }
        set {
            UserDefaults.standard.setValue(newValue?.timeIntervalSince1970, forKey: Constants.lastProcessedKey)
        }
    }

    // MARK: - Lifecycle

    /// Will initialize a new poller instance with the given props.
    /// - Parameters:
    ///   - logStore: The ``OSLogStore`` instance to poll
    ///   - logger: Logger instance for any console output
    init(logStore: OSLogStore, logger: Logger) {
        self.logStore = logStore
        self.logger = logger
    }

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
    
    /// Will assess the given entry and ensure it is both a valid `OSLogEntryLog` instance.
    /// - Parameter entry: The entry to assess.
    /// - Returns: `OSLogEntryLog` or `nil`
    func validateLogEntry(_ entry: OSLogEntry) -> OSLogEntryLog? {
        entry as? OSLogEntryLog
    }

    /// Will poll logs since the last processed time position and send to any registered drivers for validation and processing.
    /// - Parameter date: Optional date to request logs from. Leave this `nil` to default to the `lastProcessed` property.
    func pollLatestLogs(from date: Date? = nil) {
        do {
            var predicate: NSPredicate?
            let fromDate = date ?? lastProcessed
            if let fromDate {
                if datePredicate == nil {
                    datePredicate = NSPredicate(format: "date > $DATE")
                }
                
                predicate = datePredicate?.withSubstitutionVariables(["DATE": fromDate])
            }
            let items = try logStore.getEntries(matching: predicate).compactMap(validateLogEntry)
            let sortedItems = items.sorted(by: { $0.date <= $1.date })
            drivers.forEach { driver in
                sortedItems.forEach(driver.processLogIfValid)
            }
            lastProcessed = sortedItems.last?.date ?? lastProcessed
        } catch {
            logger.error("Error: Unable to get log entries from store: `\(error.localizedDescription)`")
        }
    }
}
