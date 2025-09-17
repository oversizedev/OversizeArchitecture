//
// Copyright © 2025 Alexander Romanov
// ProductListView.swift, created on 17.09.2025
//

import SwiftUI

public struct ProductListView: ViewProtocol {

    @Bindable var viewState: ProductListViewState
    let reducer: Reducer<ProductListViewModel>

    public init(viewState: ProductListViewState, reducer: Reducer<ProductListViewModel>) {
        self.viewState = viewState
        self.reducer = reducer
    }

    public var body: some View {
        Text(viewState.title)
    }
}

#Preview("List") {
    ProductListModule.build(
        input: ProductListInput(),
        output: ProductListOutput()
    )
}
