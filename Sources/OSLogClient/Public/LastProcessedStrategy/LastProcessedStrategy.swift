//
//  LastProcessedStrategy.swift
//
//
//  Created by Michael O'Brien on 2/6/2024.
//

import Foundation

/// Enumeration of supported strategies for storing and updating the `Date` the log store was last successfully queried and processed.
public protocol LastProcessedStrategy: Sendable {
    /// The most recent `Date` of a processed/polled log
    var date: Date? { get }

    /// Will assign the `date` to the given value.
    ///
    /// - Parameter date: The date to assign.
    mutating func setLastProcessedDate(_ date: Date?)
}
