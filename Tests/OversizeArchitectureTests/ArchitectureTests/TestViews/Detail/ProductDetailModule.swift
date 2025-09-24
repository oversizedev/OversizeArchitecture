import Foundation
@testable import OversizeArchitecture

public struct ProductDetailInput: Sendable {
    public let source: Source

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

    public var productId: UUID {
        switch source {
        case let .id(id):
            id
        case let .product(product):
            product.id
        }
    }
}

public struct ProductDetailOutput: Sendable {
    public init() {}
}

@Module
public enum ProductDetailModule: ModuleProtocol {}
