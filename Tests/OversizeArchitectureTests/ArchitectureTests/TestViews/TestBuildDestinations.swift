//
// Copyright © 2025 Alexander Romanov
// TestBuildDestinations.swift, created on 17.09.2025
//

@testable import OversizeArchitecture
import SwiftUI

public enum TestBuildDestinations {
    case productList
    case productDetail(id: UUID)
    case productEdit(id: UUID? = nil, onSave: @Sendable (_ product: Product) -> Void)
}

public extension TestBuildDestinations {
    @ViewBuilder @MainActor
    var view: some View {
        switch self {
        case .productList:
            ProductListModule.build()
        case let .productDetail(id):
            ProductDetailModule.build(input: .init(id: id))
        case let .productEdit(id, onSave):
            ProductEditModule.build(
                input: id.map { .init(id: $0) } ?? .init(),
                output: .init(onSave: onSave)
            )
        }
    }
}
