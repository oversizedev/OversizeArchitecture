//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModel.swift, created on 17.09.2025
//

import SwiftUI

public actor ProductEditViewModel: ViewModelProtocol {
    public typealias Input = ProductEditInput
    public typealias Output = ProductEditOutput
    public typealias ViewState = ProductEditViewState

    public enum Action: Sendable {
        case onAppear
        case onTapSave
    }

    public var state: ProductEditViewState
    private let input: ProductEditInput?
    private let output: ProductEditOutput?

    public init(state: ProductEditViewState, input: ProductEditInput?, output: ProductEditOutput?) {
        self.state = state
        self.input = input
        self.output = output
    }

    public func handleAction(_ action: Action) async {
        switch action {
        case .onAppear:
            await onAppear()
        case .onTapSave:
            await onTapSave()
        }
    }

    private func onAppear() async {
        // Load data if needed
    }

    @MainActor
    private func onTapSave() async {
        let product = Product(id: await state.productId, name: await state.name)
        output?.onSave(product)
    }
}
