//
//  ProcessInfoProvider.swift
//  
//
//  Created by Michael O'Brien on 2/6/2024.
//

import Foundation

/// Internal protocol used to facilitate unit-testing only support for some scenarios.
/// This is due to not being able to use a traditional spy/mock setup for actors.
protocol ProcessInfoEnvironmentProvider: AnyObject {

    /// Dictionary of environment variables available from the current process.
    var processInfoEnvironment: [String : String] { get }
}
