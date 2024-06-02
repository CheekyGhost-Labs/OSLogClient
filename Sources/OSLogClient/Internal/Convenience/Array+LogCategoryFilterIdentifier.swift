//
//  Array+LogCategoryFilterIdentifier.swift
//
//
//  Created by Joshua Asbury on 2/6/2024.
//

extension [LogCategoryFilter] {
    /// Concatenates all the ``LogCategory/identifier``s or `<no-filters>` if the array is empty.
    var identifier: String {
        if isEmpty {
            return "<no-filters>"
        } else {
            return map(\.identifier).joined(separator: ",")
        }
    }
}
