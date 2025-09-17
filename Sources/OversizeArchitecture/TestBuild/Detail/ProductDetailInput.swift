import Foundation

public struct ProductDetailInput: Sendable {
    public let id: UUID

    public init(id: UUID) {
        self.id = id
    }
}

public struct ProductDetailOutput: Sendable {
    public init() {}
}
