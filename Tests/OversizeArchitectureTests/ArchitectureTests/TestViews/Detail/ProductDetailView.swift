//
// Copyright © 2025 Alexander Romanov
// MealProductDetailScreen.swift, created on 10.07.2025
//

@testable import OversizeArchitecture
import SwiftUI

@View(module: ProductDetail.self)
public struct ProductDetailView: ViewProtocol {
    public var body: some View {
        Text(viewState.name)
            .task { reducer.callAsFunction(.onAppear) }
    }
}

#Preview("Detail") {
    ProductDetail.build(input: .init(id: UUID()))
}
