//
// Copyright © 2025 Alexander Romanov
// ProductEditInput.swift, created on 17.09.2025
//

import Foundation

public struct ProductEditInput: Sendable {
    public let id: UUID?

    public init(id: UUID? = nil) {
        self.id = id
    }
}

public struct ProductEditOutput: Sendable {
    public let onSave: @Sendable (_ product: Product) -> Void

    public init(onSave: @escaping @Sendable (_ product: Product) -> Void) {
        self.onSave = onSave
    }
}