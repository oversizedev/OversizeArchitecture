//
// Copyright © 2025 Alexander Romanov
// Product.swift, created on 17.09.2025
//

import Foundation

public struct Product: Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
