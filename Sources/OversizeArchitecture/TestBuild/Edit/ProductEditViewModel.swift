//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModel.swift, created on 17.09.2025
//

import SwiftUI

@ViewModel
public actor ProductEditViewModel: ViewModelProtocol {

    public var state: ProductEditModule.ViewState
    private let input: ProductEditModule.Input?
    private let output: ProductEditModule.Output?

    public init(state: ProductEditModule.ViewState, input: ProductEditModule.Input?, output: ProductEditModule.Output?) {
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
