//
//  Sequence+Concurrency.swift
//
//
//  Created by Michael O'Brien on 23/5/2024.
//

import Foundation

extension Sequence {

    /// Performs the given operation on each element sequentially using async/await.
    /// - Parameter operation: The operation to invoke.
    func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
    }

    /// Performs the given operation on each element concurrently using async/await.
    /// - Parameter operation: The operation to invoke.
    func concurrentForEach(_ operation: @escaping (Element) async -> Void) async {
        await withTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    await operation(element)
                }
            }
        }
    }
}
