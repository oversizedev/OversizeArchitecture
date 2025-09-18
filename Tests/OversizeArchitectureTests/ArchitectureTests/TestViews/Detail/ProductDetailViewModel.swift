//
// Copyright © 2025 Alexander Romanov
// MealProductDetailViewModel.swift, created on 10.07.2025
//

import SwiftUI
@testable import OversizeArchitecture

@ViewModel(module: ProductDetailModule.self)
public actor ProductDetailViewModel: ViewModelProtocol {

    func onAppear() async {
        guard let input = input else { return }

        switch input.source {
        case .id(let id):
            await loadProduct(id: id)
        case .product(let product):
            await updateState(with: product)
        }
    }

    private func loadProduct(id: UUID) async {
        let product = Product(id: id, name: "Loaded Product")
        await updateState(with: product)
    }

    private func updateState(with product: Product) async {
        await state.update { viewState in
            viewState.name = product.name
        }
    }
}
