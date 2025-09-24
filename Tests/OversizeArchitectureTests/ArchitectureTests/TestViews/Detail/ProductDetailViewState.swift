//
// Copyright © 2025 Alexander Romanov
// MealProductDetailViewState.swift, created on 10.07.2025
//

@testable import OversizeArchitecture
import SwiftUI

@Observable
public final class ProductDetailViewState: ViewStateProtocol {
    public let id: UUID
    public var name: String = "Product"

    public init(input: ProductDetailModule.Input?) {
        id = input?.productId ?? UUID()
    }
}
