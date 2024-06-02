//
//  LogCategoryFilter.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

/// A definition of a condition which the ``LogDriver`` uses to restrict logs that will be processed.
public struct LogCategoryFilter: Hashable, ExpressibleByStringLiteral {
    typealias EvaluatorFunction = (_ category: String) -> Bool

    /// An identifier for this filter and its condition.
    let identifier: String

    /// The function that performs evaluation.
    private let evaluator: EvaluatorFunction

    init(identifier: String, evaluator: @escaping EvaluatorFunction) {
        self.identifier = identifier
        self.evaluator = evaluator
    }

    /// Creates a ``LogCategoryFilter`` which compares only the `OSLogEntryLog` category with the supplied category.
    ///
    /// - Note: The supplied category is compared case-insensitive.
    /// - Parameter value: The category to compare against.
    /// - Returns: The ``LogCategoryFilter`` to provide to a ``LogFilter``.
    public init(stringLiteral value: StringLiteralType) {
        let value = value.lowercased()
        self.init(identifier: "category:matches(\(value))") { category in
            return value == category
        }
    }

    /// Performs checks against the provided subsystem and category against the evaluator function supplied during initialization.
    ///
    /// - Parameter category: The category of the `OSLogEntryLog` object. The value will be lowercased before being evaluated.
    /// - Returns: `Bool` result from the evaluator function.
    func evaluate(againstCategory category: String) -> Bool {
        evaluator(category.lowercased())
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: LogCategoryFilter, rhs: LogCategoryFilter) -> Bool {
        lhs.identifier == rhs.identifier
    }

    // MARK: Conditions

    /// - SeeAlso: ``init(stringLiteral:)``
    public static func matches(_ value: String) -> LogCategoryFilter {
        return LogCategoryFilter(stringLiteral: value)
    }

    /// Creates a ``LogCategoryFilter`` which evaluates if the `OSLogEntryLog` category begins with the specified prefix.
    ///
    /// - Note: The supplied prefix is compared case-insensitive.
    /// - Parameter prefix: The prefix to compare against.
    /// - Returns: The ``LogCategoryFilter`` to provide to a ``LogFilter``.
    public static func startsWith(_ prefix: String) -> LogCategoryFilter {
        let prefix = prefix.lowercased()
        return LogCategoryFilter(identifier: "category:startsWith(\(prefix))") { category in
            category.hasPrefix(prefix)
        }
    }

    /// Creates a ``LogCategoryFilter`` which evaluates if the `OSLogEntryLog` category contains the specified value.
    ///
    /// - Note: The supplied value is compared case-insensitive.
    /// - Parameter value: The category to compare against.
    /// - Returns: The ``LogCategoryFilter`` to provide to a ``LogFilter``.
    public static func contains(_ value: String) -> LogCategoryFilter {
        let value = value.lowercased()
        return LogCategoryFilter(identifier: "category:contains(\(value))") { category in
            category.contains(value)
        }
    }

    /// Creates a ``LogCategoryFilter`` which evaluates to the inverse of the supplied ``LogCategoryFilter``.
    ///
    /// The output of this filter will be as follows:
    /// | Supplied Filter's Output | This Filter Output |
    /// | --- | --- |
    /// | `true` | `false` |
    /// | `false` | `true` |
    ///
    /// - Parameter filter: The filter to invert.
    /// - Returns: The ``LogCategoryFilter`` to provide to a ``LogFilter``.
    public static func not(_ filter: LogCategoryFilter) -> LogCategoryFilter {
        return LogCategoryFilter(identifier: "not(\(filter.identifier))") { category in
            let result = filter.evaluate(againstCategory: category)
            return !result
        }
    }
}
