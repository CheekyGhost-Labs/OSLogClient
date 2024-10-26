//
//  InMemoryLastProcessedStrategy.swift
//
//
//  Created by Joshua Asbury on 24/8/2024.
//

public final class InMemoryLastProcessedStrategy: LastProcessedStrategy, Equatable, @unchecked Sendable {

    public var date: Date?

    public func setLastProcessedDate(_ date: Date?) {
        self.date = date
    }

    public static func == (lhs: InMemoryLastProcessedStrategy, rhs: InMemoryLastProcessedStrategy) -> Bool {
        lhs.date == rhs.date
    }
}

public extension LastProcessedStrategy where Self == InMemoryLastProcessedStrategy {
    static var inMemory: Self {
        Self()
    }
}
