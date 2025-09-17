//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModel.swift, created on 17.09.2025
//

import SwiftUI

@ViewModel
public actor ProductEditViewModel: ViewModelProtocol {

    public var state: ProductListModule.ViewState
    private let input: ProductListModule.Input?
    private let output: ProductListModule.Output?

    public init(state: ProductListModule.ViewState, input: ProductListModule.Input?, output: ProductListModule.Output?) {
        self.state = state
        self.input = input
        self.output = output
    }

    func onAppear() async { }

    func onTapSave() async {
        let product = await Product(id: state.productId, name: state.name)
        output?.onSave(product)
    }
}
