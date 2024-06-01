//
//  File.swift
//  
//
//  Created by Michael O'Brien on 2/6/2024.
//

import Foundation

/// Enumeration of supported strategies for storing and updating the datetime the log store was last successfully queried and processed.
public enum LastProcessedStrategy: Equatable {
    case userDefaults(key: String)
    case inMemory
    
    /// Will return the library default strategy which resolves to ``LastProcessedStrategy/userDefaults(key:)``
    public static var `default`: Self {
        .userDefaults(key: "com.cheekyghost.axologl.lastProcessed")
    }
}
