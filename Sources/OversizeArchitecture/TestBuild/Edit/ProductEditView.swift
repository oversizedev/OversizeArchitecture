//
// Copyright © 2025 Alexander Romanov
// ProductEditView.swift, created on 17.09.2025
//

import SwiftUI

public struct ProductEditView: ViewProtocol {

    @Bindable var viewState: ProductEditViewState
    let reducer: Reducer<ProductEditViewModel>

    public init(viewState: ProductEditViewState, reducer: Reducer<ProductEditViewModel>) {
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
    }

}

#Preview("Edit") {
    Builder<ProductEditModule>.build(
        input: ProductEditInput(),
        output: ProductEditOutput(onSave: { product in
            print("Saved: \(product.name)")
        })
    )
}
