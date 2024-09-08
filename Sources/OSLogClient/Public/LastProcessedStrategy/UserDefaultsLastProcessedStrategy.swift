//
//  UserDefaultsLastProcessedStrategy.swift
//
//
//  Created by Joshua Asbury on 24/8/2024.
//

import Foundation

public struct UserDefaultsLastProcessedStrategy: LastProcessedStrategy {
    let defaults: UserDefaults
    let key: String

    public var date: Date? {
        guard let timestamp = defaults.value(forKey: key) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    public init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.defaults = defaults
    }

    public mutating func setLastProcessedDate(_ date: Date?) {
        if let date {
            defaults.setValue(date.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}

public extension LastProcessedStrategy where Self == UserDefaultsLastProcessedStrategy {
    static func userDefaults(key: String, defaults: UserDefaults = .standard) -> Self {
        Self(key: key, defaults: defaults)
    }

    /// Will return the library default strategy which resolves to ``LastProcessedStrategy/userDefaults(key:)``
    static var `default`: Self {
        .userDefaults(key: "com.cheekyghost.axologl.lastProcessed")
    }
}
