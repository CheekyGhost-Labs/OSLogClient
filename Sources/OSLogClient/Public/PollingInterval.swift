//
//  PollingInterval.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation

/// Enumeration of supported polling interval options.
public enum PollingInterval: Equatable {
    /// Represents an interval of 10 seconds
    case short
    /// Represents an interval of 30 seconds
    case medium
    /// Represents an interval of 60 seconds
    case long
    /// Represents a custom polling interval (in seconds)
    ///
    /// **Note:** A hard minimum of 1 second is enforced.
    case custom(TimeInterval)

    /// Returns the raw time interval in seconds.
    public var rawValue: TimeInterval {
        switch self {
        case .short:
            return 10
        case .medium:
            return 30
        case .long:
            return 60
        case .custom(let timeInterval):
            return max(timeInterval, 1)
        }
    }

    /// Returns the raw time interval in nanoseconds.
    var nanoseconds: UInt64 {
        UInt64(rawValue) * 1_000_000_000
    }
}
