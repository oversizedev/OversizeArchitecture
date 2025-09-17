//
// Copyright © 2025 Alexander Romanov
// TestBuildDestinations.swift, created on 17.09.2025
//

import SwiftUI

public enum TestBuildDestinations {
    case productList
    case productDetail(id: UUID)
    case productEdit(id: UUID? = nil, onSave: @Sendable (_ product: Product) -> Void)
}

extension TestBuildDestinations {
    @ViewBuilder @MainActor
    public var view: some View {
        switch self {
        case .productList:
            Builder<ProductListModule>.build(
                input: ProductListInput(),
                output: ProductListOutput()
            )
        case .productDetail(let id):
            Builder<ProductDetailModule>.build(
                input: ProductDetailInput(id: id),
                output: ProductDetailOutput()
            )
        case .productEdit(let id, let onSave):
            Builder<ProductEditModule>.build(
                input: ProductEditInput(id: id),
                output: ProductEditOutput(onSave: onSave)
            )
        }
    }
}
