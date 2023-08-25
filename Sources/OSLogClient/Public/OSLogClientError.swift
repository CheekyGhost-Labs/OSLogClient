//
//  OSLogClientError.swift
//  OSLogClient
//
//  Copyright © 2023 CheekyGhost Labs. All rights reserved.
//

import Foundation

/// Enumeration of errors the ``OSLogClient`` can emit.
public enum OSLogClientError: LocalizedError {
    case unableToLoadLogStore(error: String)
    case clientAlreadyInitialized

    public var errorDescription: String? {
        failureReason
    }

    public var failureReason: String? {
        switch self {
        case .unableToLoadLogStore(let error):
            return "OSLogStore failed to resolve: \(error)"
        case .clientAlreadyInitialized:
            return "OSLogClient has already been initialized."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .unableToLoadLogStore:
            return "Review the underlying error and try again."
        case .clientAlreadyInitialized:
            return "OSLogClient has already been initialized."
        }
    }
}
