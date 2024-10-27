//
//  UserDefaultsLastProcessedStrategy.swift
//
//
//  Created by Joshua Asbury on 24/8/2024.
//

import Foundation

final class SendableUserDefaults: @unchecked Sendable {

    var target: UserDefaults

    init(_ target: UserDefaults) {
        self.target = target
    }

    func setValue(_ value: Any?, forKey key: String) {
        target.set(value, forKey: key)
    }

    func value(forKey key: String) -> Any? {
        target.value(forKey: key)
    }

    func removeObject(forKey defaultName: String) {
        target.removeObject(forKey: defaultName)
    }
}

public struct UserDefaultsLastProcessedStrategy: LastProcessedStrategy, Equatable, Sendable {

    // MARK: - Properties

    var sendableDefaults: SendableUserDefaults

    var defaults: UserDefaults {
        sendableDefaults.target
    }

    let key: String

    public var date: Date? {
        guard let timestamp = defaults.value(forKey: key) as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    // MARK: - Lifecycle

    public init(key: String, defaults: UserDefaults = .standard) {
        self.key = key
        self.sendableDefaults = SendableUserDefaults(defaults)
    }

    public mutating func setLastProcessedDate(_ date: Date?) {
        if let date {
            defaults.setValue(date.timeIntervalSince1970, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    public static func == (lhs: UserDefaultsLastProcessedStrategy, rhs: UserDefaultsLastProcessedStrategy) -> Bool {
        lhs.date == rhs.date
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
