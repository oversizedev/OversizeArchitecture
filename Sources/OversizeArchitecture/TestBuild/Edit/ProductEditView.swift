//
// Copyright © 2025 Alexander Romanov
// ProductEditView.swift, created on 17.09.2025
//

import SwiftUI

public struct ProductEditView: ViewProtocol {

    @Bindable var viewState: ProductEditModule.ViewState
    let reducer: Reducer<ProductEditModule.ViewModel>

    public init(viewState: ProductEditModule.ViewState, reducer: Reducer<ProductEditModule.ViewModel>) {
        self.viewState = viewState
        self.reducer = reducer
    }

    public var body: some View {
        VStack {
            Text(viewState.title)

            TextField("Name", text: $viewState.name)

            Button("Save", systemImage: "checkmark") {
                reducer.callAsFunction(.onTapSave)
            }
        }
        .task { reducer.callAsFunction(.onAppear) }
    }

}

#Preview("Edit") {
    ProductEditModule.build(
        input: ProductEditInput(),
        output: ProductEditOutput(onSave: { product in
            print("Saved: \(product.name)")
        })
    )
}
