//
// Copyright © 2025 Alexander Romanov
// ProductEditInput.swift, created on 17.09.2025
//

import Foundation
@testable import OversizeArchitecture

public struct ProductEditInput: Sendable {
    public let source: Source?

    public enum Source: Sendable {
        case id(UUID)
        case product(Product)
    }

    public init(id: UUID) {
        source = .id(id)
    }

    public init(product: Product) {
        source = .product(product)
    }

    public init() {
        source = nil
    }

    public var productId: UUID? {
        switch source {
        case let .id(id):
            id
        case let .product(product):
            product.id
        case .none:
            nil
        }
    }
}

public struct ProductEditOutput: Sendable {
    public let onSave: @Sendable (_ product: Product) -> Void

    public init(onSave: @escaping @Sendable (_ product: Product) -> Void) {
        self.onSave = onSave
    }
}

@Module
public enum ProductEdit: ModuleProtocol {}
