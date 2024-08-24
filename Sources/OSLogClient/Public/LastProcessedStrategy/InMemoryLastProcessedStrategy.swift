//
//  InMemoryLastProcessedStrategy.swift
//
//
//  Created by Joshua Asbury on 24/8/2024.
//

public class InMemoryLastProcessedStrategy: LastProcessedStrategy {
    public var date: Date?

    public func setLastProcessedDate(_ date: Date?) {
        self.date = date
    }
}

extension LastProcessedStrategy where Self == InMemoryLastProcessedStrategy {
    static var inMemory: Self {
        Self()
    }
}
