//
// Copyright © 2025 Alexander Romanov
// ProductListView.swift, created on 17.09.2025
//

import SwiftUI
@testable import OversizeArchitecture

@View(module: ProductListModule.self)
public struct ProductListView: ViewProtocol {
    public var body: some View {
        Text(viewState.title)
    }
}

#Preview("List") {
    ProductListModule.build()
}
