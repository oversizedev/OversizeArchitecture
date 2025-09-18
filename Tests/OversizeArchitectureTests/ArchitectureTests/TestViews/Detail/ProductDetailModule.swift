import Foundation
@testable import OversizeArchitecture

public struct ProductDetailInput: Sendable {
    public let source: Source

    public enum Source: Sendable {
        case id(UUID)
        case product(Product)
    }

    public init(id: UUID) {
        self.source = .id(id)
    }

    public init(product: Product) {
        self.source = .product(product)
    }

    public var productId: UUID {
        switch source {
        case .id(let id):
            return id
        case .product(let product):
            return product.id
        }
    }
}

public struct ProductDetailOutput: Sendable {
    public init() {}
}

@Module
public enum ProductDetailModule: ModuleProtocol { }
