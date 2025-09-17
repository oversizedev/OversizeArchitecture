//
// Copyright © 2025 Alexander Romanov
// MealProductDetailScreen.swift, created on 10.07.2025
//

import SwiftUI

public struct ProductDetailView: ViewProtocol {

    @Bindable var viewState: ProductDetailModule.ViewState
    let reducer: Reducer<ProductDetailModule.ViewModel>

    public init(viewState: ProductDetailModule.ViewState, reducer: Reducer<ProductDetailModule.ViewModel>) {
        self.viewState = viewState
        self.reducer = reducer
    }

    public var body: some View {
        Text(viewState.name)
            .task { reducer.callAsFunction(.onAppear) }
    }
}

#Preview("Detail") {
    ProductDetailModule.build(input: .init(id: UUID()))
}
