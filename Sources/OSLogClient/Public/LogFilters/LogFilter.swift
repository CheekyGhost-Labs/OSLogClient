//
//  LogFilter.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

/// A definition of a condition which the ``LogDriver`` uses to restrict logs that will be processed.
public struct LogFilter: Hashable {
    typealias EvaluatorFunction = (_ subsystem: String, _ category: String) -> Bool

    /// An identifier for this filter and its condition.
    let identifier: String

    /// The function that performs evaluation.
    private let evaluator: EvaluatorFunction

    init(identifier: String, evaluator: @escaping EvaluatorFunction) {
        self.identifier = identifier
        self.evaluator = evaluator
    }

    /// Performs checks against the provided subsystem and category against the evaluator function supplied during initialization.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem of the `OSLogEntryLog` object. The value will be lowercased before being evaluated.
    ///   - category: The category of the `OSLogEntryLog` object. The value will be lowercased before being evaluated.
    /// - Returns: `Bool` result from the evaluator function.
    func evaluate(againstSubsystem subsystem: String, category: String) -> Bool {
        evaluator(subsystem.lowercased(), category.lowercased())
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: LogFilter, rhs: LogFilter) -> Bool {
        lhs.identifier == rhs.identifier
    }

    // MARK: Exact match

    /// Creates a ``LogFilter`` which compares only the `OSLogEntryLog` subsystem with the supplied subsystem.
    ///
    /// - Note: The supplied subsystem is compared case-insensitive.
    /// - Parameter value: The subsystem to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    public static func subsystem(_ value: String) -> LogFilter {
        let value = value.lowercased()
        return LogFilter(identifier: "subsystem:matches(\(value))") { subsystem, _ in
            return value == subsystem
        }
    }

    /// Creates a ``LogFilter`` which compares the `OSLogEntryLog` subsystem and category with the supplied subsystem and category filters.
    ///
    /// - Note: The supplied subsystem is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - value: The subsystem to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    public static func subsystem(_ value: String, categories: [LogCategoryFilter]) -> LogFilter {
        let value = value.lowercased()
        let subsystemFilter = LogFilter.subsystem(value)
        return combine(subsystemFilter: subsystemFilter, categoryFilters: categories)
    }

    /// Creates a ``LogFilter`` which compares the `OSLogEntryLog` subsystem and category with the supplied subsystem and category filters.
    ///
    /// - Note: The supplied subsystem is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - value: The subsystem to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    @inlinable public static func subsystem(_ value: String, categories: LogCategoryFilter...) -> LogFilter {
        return subsystem(value, categories: categories)
    }

    // MARK: Starts With

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem begins with the specified prefix.
    ///
    /// - Note: The supplied prefix is compared case-insensitive.
    /// - Parameter prefix: The prefix to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    public static func subsystem(startsWith prefix: String) -> LogFilter {
        let prefix = prefix.lowercased()
        return LogFilter(identifier: "subsystem:startsWith(\(prefix))") { subsystem, _ in
            subsystem.hasPrefix(prefix)
        }
    }

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem begins with the specified prefix and if the `OSLogEntryLog` category matches the category filters.
    ///
    /// - Note: The supplied prefix is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - prefix: The prefix to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    public static func subsystem(startsWith prefix: String, categories: [LogCategoryFilter]) -> LogFilter {
        let prefix = prefix.lowercased()
        let subsystemFilter = LogFilter.subsystem(startsWith: prefix)
        return combine(subsystemFilter: subsystemFilter, categoryFilters: categories)
    }

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem begins with the specified prefix and if the `OSLogEntryLog` category matches the category filters.
    ///
    /// - Note: The supplied prefix is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - prefix: The prefix to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    @inlinable public static func subsystem(startsWith prefix: String, categories: LogCategoryFilter...) -> LogFilter {
        return subsystem(startsWith: prefix, categories: categories)
    }

    // MARK: Contains

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem contains the specified value.
    ///
    /// - Note: The supplied value is compared case-insensitive.
    /// - Parameter value: The subsystem to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    public static func subsystem(contains value: String) -> LogFilter {
        let value = value.lowercased()
        return LogFilter(identifier: "subsystem:contains(\(value))") { subsystem, _ in
            subsystem.contains(value)
        }
    }

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem contains the specified value and if the `OSLogEntryLog` category matches the category filters.
    ///
    /// - Note: The supplied value is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - value: The subsystem to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    public static func subsystem(contains value: String, categories: [LogCategoryFilter]) -> LogFilter {
        let value = value.lowercased()
        let subsystemFilter = LogFilter.subsystem(contains: value)
        return combine(subsystemFilter: subsystemFilter, categoryFilters: categories)
    }

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` subsystem contains the specified value and if the `OSLogEntryLog` category matches the category filters.
    ///
    /// - Note: The supplied value is compared case-insensitive. Categories are evaluated in order and until a filter evaluates `true`. See ``LogCategoryFilter``.
    /// - Parameters:
    ///   - value: The subsystem to compare against.
    ///   - categories: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    /// - SeeAlso: ``LogCategoryFilter``
    @inlinable public static func subsystem(contains value: String, categories: LogCategoryFilter...) -> LogFilter {
        return subsystem(contains: value, categories: categories)
    }

    // MARK: Syntax-sugar

    /// Creates a ``LogFilter`` which evaluates if the `OSLogEntryLog` category matches the filters, it does not compare the subsystem.
    ///
    /// - Note: The supplied value is compared case-insensitive.
    /// - Parameter categoryFilter: The category filters to compare against.
    /// - Returns: The ``LogFilter`` to provide to a ``LogDriver``.
    public static func category(_ categoryFilter: LogCategoryFilter) -> LogFilter {
        return LogFilter(identifier: categoryFilter.identifier) { _, category in
            categoryFilter.evaluate(againstCategory: category)
        }
    }

    // MARK: - Convenience

    /// Convenience to combine a subsystem filter with an array of category filters.
    ///
    /// - NOTE: This function will ensure the subsystem and category are evaluated in a performant manner by not evaluating the categories
    ///         if the subsystem evaluation fails. When evaluating the categories it will also stop evaluation early if any filter returns `true`.
    private static func combine(subsystemFilter: LogFilter, categoryFilters: [LogCategoryFilter]) -> LogFilter {
        return LogFilter(identifier: "\(subsystemFilter.identifier)&[\(categoryFilters.identifier)]") { subsystem, category in
            // Evaluated as part of the same expression to utilise short-circuit logic
            return subsystemFilter.evaluate(againstSubsystem: subsystem, category: category) &&
                categoryFilters.contains(where: { $0.evaluate(againstCategory: category) })
        }
    }
}
