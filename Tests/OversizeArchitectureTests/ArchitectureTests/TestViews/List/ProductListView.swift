//
// Copyright © 2025 Alexander Romanov
// ProductListView.swift, created on 17.09.2025
//

import SwiftUI
@testable import OversizeArchitecture

public struct ProductListView: ViewProtocol {

    @Bindable var viewState: ProductListModule.ViewState
    let reducer: Reducer<ProductListModule.ViewModel>

    public init(viewState: ProductListModule.ViewState, reducer: Reducer<ProductListModule.ViewModel>) {
        self.viewState = viewState
        self.reducer = reducer
    }

    public var body: some View {
        Text(viewState.title)
    }
}

#Preview("List") {
    ProductListModule.build()
}
