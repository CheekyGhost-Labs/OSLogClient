//
//  LogClient+PollingConfiguration.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation
import OSLog

extension LogClient {

    enum Constants {
        static let lastProcessedKey: String = "com.cheekyghost.axologl.lastProcessed"
    }

    actor PollingConfiguration {

        /// Bool whether the poller is enabled.
        var isEnabled: Bool = false

        /// The current polling interval. Defaults to ``PollingInterval/medium``
        /// - See: ``PollingInterval``
        var pollingInterval: PollingInterval
        
        /// Bool flag indicating whether polling should cease if there are no registered drivers.
        ///
        /// - Note: The inverse also applies, in that if drivers are registered polling will start again
        /// if the `isEnabled` flag is `true`.
        var shouldPauseIfNoRegisteredDrivers: Bool = true

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

        init(isEnabled: Bool, pollingInterval: PollingInterval) {
            self.isEnabled = isEnabled
            self.pollingInterval = pollingInterval
        }

        // MARK: - Setters

        func setIsEnabled(_ flag: Bool) {
            isEnabled = flag
        }

        func setPollingInterval(_ value: PollingInterval) {
            pollingInterval = value
        }

        func setShouldPauseIfNoRegisteredDrivers(_ flag: Bool) {
            shouldPauseIfNoRegisteredDrivers = flag
        }

        func setLastProcessed(_ value: Date?) {
            lastProcessed = value
        }
    }
}
