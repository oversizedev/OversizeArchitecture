//
// Copyright © 2025 Alexander Romanov
// ProductEditView.swift, created on 17.09.2025
//

import SwiftUI
@testable import OversizeArchitecture

@View(module: ProductEditModule.self)
public struct ProductEditView: ViewProtocol {
    public var body: some View {
        VStack {
            Text(viewState.mode.title)

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
