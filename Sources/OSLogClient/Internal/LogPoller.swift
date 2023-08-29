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

    /// Will register the given driver instance to receive any polled logs.
    ///
    /// - Parameter driver: The driver to register
    func registerDriver(_ driver: LogDriver) {
        guard !drivers.contains(where: { $0.id ==  driver.id }) else {
            logger.error("Driver instance with id `\(driver.id)` is already registered.")
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
    func pollLatestLogs() {
        do {
            var predicate: NSPredicate?
            if let lastProcessed {
                if datePredicate == nil {
                    datePredicate = NSPredicate(format: "date > $DATE")
                }
                
                predicate = datePredicate?.withSubstitutionVariables(["DATE": lastProcessed])
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
