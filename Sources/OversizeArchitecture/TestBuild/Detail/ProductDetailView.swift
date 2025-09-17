//
// Copyright © 2025 Alexander Romanov
// MealProductDetailScreen.swift, created on 10.07.2025
//

import SwiftUI

public struct ProductDetailView: ViewProtocol {

    @Bindable var viewState: ProductDetailViewState
    let reducer: Reducer<ProductDetailViewModel>

    public init(viewState: ProductDetailViewState, reducer: Reducer<ProductDetailViewModel>) {
        self.viewState = viewState
        self.reducer = reducer
    }

    public var body: some View {
        Text(viewState.name)
            .task { reducer.callAsFunction(.onAppear) }
    }
}

#Preview("Detail") {
    Builder<ProductDetailModule>.build(
        input: ProductDetailInput(id: UUID()),
        output: ProductDetailOutput()
    )
}
