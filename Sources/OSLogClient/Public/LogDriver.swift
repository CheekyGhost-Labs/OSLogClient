//
//  LogDriver.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import OSLog

/// `LogDriver` instances are responsible for handling processed os logs.
/// Instances, when registered with the ``OSLogClient`` instance, will be sent logs from the `OSLogStore`.
/// If  ``LogDriver/LogSource`` enums are provided, any incoming logs will be assessed against the log source rules and ignored if no matches are found.
open class LogDriver: Equatable, CustomStringConvertible, CustomDebugStringConvertible {

    // MARK: - Supplementary

    public enum LogSource: Equatable {
        case subsystem(String)
        case subsystemAndCategories(subsystem: String, categories: [String])
    }

    /// Enumeration of supported log levels.
    public enum LogLevel: String, CaseIterable {
        /// The log level was never specified.
        case undefined
        /// A log level that captures diagnostic information.
        case debug
        /// The log level that captures additional information.
        case info
        /// The log level that captures notifications.
        case notice
        /// The log level that captures errors.
        case error
        /// The log level that captures fault information.
        case fault

        // MARK: - Internal Convenience

        /// Convenience initializer to create from an `OSLogEntryLog.Level` type.
        /// Any unknowns will default to ``LogLevel/undefined``
        /// - Parameter osLogLevel: The raw `OSLogEntryLog.Level` to transform.
        public init(_ osLogLevel: OSLogEntryLog.Level) {
            switch osLogLevel {
            case .undefined:
                self = .undefined
            case .debug:
                self = .debug
            case .info:
                self = .info
            case .notice:
                self = .notice
            case .error:
                self = .error
            case .fault:
                self = .fault
            @unknown default:
                self = .undefined
            }
        }
    }

    // MARK: - Properties

    /// Unique identifier for the driver.
    let id: String
    
    /// Array of log sources to restrict logs sent to the `processLog(...)` method.
    ///
    /// Defaults to no filters.
    /// **Note:** A log is considered valid if **any** of the sources match the incoming log subsystem and category.
    /// - SeeAlso: ``LogDriver/LogSource``
    private(set) public var logSources: [LogSource]

    // MARK: - Lifecycle

    public required init(id: String, logSources: [LogSource] = []) {
        self.id = id
        self.logSources = logSources
    }

    // MARK: - Helpers
    
    /// Will add the given filters to the ``LogDriver/logFilters`` set which are used to assess logs before they are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to add.
    public final func addLogSources(_ filters: [LogSource]) {
        filters.forEach {
            if !logSources.contains($0) {
                logSources.append($0)
            }
        }
    }

    /// Will remove the given filters from the ``LogDriver/logFilters`` set which are assessed before logs are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to remove.
    public final func removeLogSources(_ filters: [LogSource]) {
        logSources.removeAll(where: { filters.contains($0) })
    }

    /// Will assess the given log entry against the current log filters set and return `true` if all filters are valid.
    /// - Parameters:
    ///   - subsystem: The subsystem of the logger the entry was made from.
    ///   - category: The category of the logger the entry was made from.
    /// - Returns: `Bool`
    func isValidLogSource(subsystem: String, category: String) -> Bool {
        guard !logSources.isEmpty else { return true }
        return logSources.contains(where: {
            switch $0 {
            case .subsystem(let system):
                return system.lowercased() == subsystem.lowercased()
            case .subsystemAndCategories(let system, let categories):
                let systemValid = system.lowercased() == subsystem.lowercased()
                let categoryValid = categories.contains(where: { $0.lowercased() == category.lowercased() })
                return systemValid && categoryValid
            }
        })
    }

    /// Will assess the given log entry and return the expected ``OSLogEntryLog`` if valid for the driver.
    /// - Parameter entry: The log entry to assess.
    /// - Returns: Bool flag if the log was processed
    func processLogIfValid(_ log: OSLogEntryLog) {
        guard isValidLogSource(subsystem: log.subsystem, category: log.category) else { return }
        let logLevel = LogLevel(log.level)
        #if os(macOS)
        processLog(
            level: logLevel,
            subsystem: log.subsystem,
            category: log.category,
            date: log.date,
            message: log.composedMessage,
            components: log.components
        )
        #else
        processLog(level: logLevel, subsystem: log.subsystem, category: log.category, date: log.date, message: log.composedMessage)
        #endif
    }

    // MARK: - Overrides

    #if os(macOS)
    /// Called when a log is detected that matches the subsystem and whose category is contained within the `categories` array.
    /// - Parameters:
    ///   - level: ``LogLevel`` type representing the underlying `OSLogEntryLog.Level`
    ///   - subsystem: The subsystem of the logger the message was logged with.
    ///   - category: The category of the logger the message was logged with.
    ///   - date: The date-time the log was recorded.
    ///   - message: The formatted/post-processed message the log generated.
    ///   - components: Array of arguments and metadata that was sent with the log.
    open func processLog(level: LogLevel, subsystem: String, category: String, date: Date, message: String, components: [OSLogMessageComponent]) {
        // no-op
    }
    #else
    /// Called when a log is detected that matches the subsystem and whose category is contained within the `categories` array.
    /// - Parameters:
    ///   - level: ``LogLevel`` type representing the underlying `OSLogEntryLog.Level`
    ///   - subsystem: The subsystem of the logger the message was logged with.
    ///   - category: The category of the logger the message was logged with.
    ///   - date: The date-time the log was recorded.
    ///   - message: The formatted/post-processed message the log generated.
    open func processLog(level: LogLevel, subsystem: String, category: String, date: Date, message: String) {
        // no-op
    }
    #endif

    // MARK: - Equatable

    public static func == (lhs: LogDriver, rhs: LogDriver) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - CustomStringConvertible

    public var description: String {
        "\(self)<\(id)>"
    }

    public var debugDescription: String {
        description
    }
}
