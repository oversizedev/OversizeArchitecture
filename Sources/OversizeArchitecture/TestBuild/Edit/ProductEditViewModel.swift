//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModel.swift, created on 17.09.2025
//

import SwiftUI

@ViewModel
public actor ProductEditViewModel: ViewModelProtocol {

    public var state: ProductEditViewState
    private let input: ProductEditInput?
    private let output: ProductEditOutput?

    public init(state: ProductEditViewState, input: ProductEditInput?, output: ProductEditOutput?) {
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
