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
            ProductListModule.build()
        case .productDetail(let id):
            ProductDetailModule.build(input: .init(id: id))
        case .productEdit(let id, let onSave):
            ProductEditModule.build(
                input: id.map { .init(id: $0) } ?? .init(),
                output: .init(onSave: onSave)
            )
        }
    }
}
