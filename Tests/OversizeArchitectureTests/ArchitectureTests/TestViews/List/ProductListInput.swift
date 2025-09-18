//
// Copyright © 2025 Alexander Romanov
// ProductListInput.swift, created on 17.09.2025
//

import Foundation

public struct ProductListInput: Sendable {
    public let filterType: FilterType

    public enum FilterType: String, CaseIterable, Sendable {
        case all, favorites

        public var title: String {
            switch self {
            case .all:
                "All Products"
            case .favorites:
                "Favorites"
            }
        }
    }

    public init(filterType: FilterType = .all) {
        self.filterType = filterType
    }
}

public struct ProductListOutput: Sendable {
    public init() {}
}