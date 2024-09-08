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
/// If  ``LogFilter``s are provided any incoming logs will be assessed against the filter rules and ignored if no matches are found.
open class LogDriver: Equatable {
    // MARK: - Supplementary

    /// Enumeration of supported log levels.
    @frozen public enum LogLevel: String, CaseIterable {
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
    public let id: String

    /// Array of log filters to restrict logs sent to the ``processLog(level:subsystem:category:date:message:)``
    /// or ``processLog(level:subsystem:category:date:message:components:)`` method.
    ///
    /// Defaults to no filters.
    /// **Note:** A log is considered valid if **any** of the filters match the incoming log subsystem and category.
    /// - SeeAlso: ``LogFilter``
    public private(set) var logFilters: Set<LogFilter>

    // MARK: - Lifecycle

    public required init(id: String, logFilters: Set<LogFilter> = []) {
        self.id = id
        self.logFilters = logFilters
    }

    public convenience init(id: String, logFilters: LogFilter...) {
        self.init(id: id, logFilters: Set(logFilters))
    }

    // MARK: - Helpers

    /// Will add the given filter to the ``LogDriver/logFilters`` set which are used to assess logs before they are sent to the `processLog(...)` method.
    /// - Parameter filter: Filter to add.
    public final func addLogFilter(_ filter: LogFilter) {
        logFilters.insert(filter)
    }

    /// Will add the given filters to the ``LogDriver/logFilters`` set which are used to assess logs before they are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to add.
    public final func addLogFilters(_ filters: [LogFilter]) {
        for filter in filters {
            logFilters.insert(filter)
        }
    }

    /// Will add the given filters to the ``LogDriver/logFilters`` set which are used to assess logs before they are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to add.
    public final func addLogFilters(_ filters: LogFilter...) {
        addLogFilters(filters)
    }

    /// Will remove the given filter from the ``LogDriver/logFilters`` set which are assessed before logs are sent to the `processLog(...)` method.
    /// - Parameter filters: Filter to remove.
    public final func removeLogFilters(_ filter: LogFilter) {
        logFilters.remove(filter)
    }

    /// Will remove the given filters from the ``LogDriver/logFilters`` set which are assessed before logs are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to remove.
    public final func removeLogFilters(_ filters: [LogFilter]) {
        for filter in filters {
            logFilters.remove(filter)
        }
    }

    /// Will remove the given filters from the ``LogDriver/logFilters`` set which are assessed before logs are sent to the `processLog(...)` method.
    /// - Parameter filters: Array of filters to remove.
    public final func removeLogFilters(_ filters: LogFilter...) {
        removeLogFilters(filters)
    }

    /// Will assess the given log entry against the current log filters set and return `true` if all filters are valid or none were defined.
    /// - Parameters:
    ///   - subsystem: The subsystem of the logger the entry was made from.
    ///   - category: The category of the logger the entry was made from
    /// - Returns: Returns `true` if no ``logFilters`` are defined or one of the filters evaluates `true`. Otherwise returns `false`.
    func isValidLogSource(subsystem: String, category: String) -> Bool {
        if logFilters.isEmpty {
            return true // No filters defined, the log is valid
        }
        for filter in logFilters where filter.evaluate(againstSubsystem: subsystem, category: category) {
            return true
        }
        return false
    }
    
    /// Will assess the given log items, and for each valid log item, invoke the ``processLog(level:subsystem:category:date:message:)`` method.
    /// - Parameter logs: The log items to process.
    func processLogs(_ logs: [OSLogEntryLog]) {
        for log in logs where isValidLogSource(subsystem: log.subsystem, category: log.category) {
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
}
