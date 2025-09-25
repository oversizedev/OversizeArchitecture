//
// Copyright © 2025 Alexander Romanov
// MealProductDetailViewModel.swift, created on 10.07.2025
//

@testable import OversizeArchitecture
import SwiftUI

@ViewModel(module: ProductDetail.self)
public actor ProductDetailViewModel: ViewModelProtocol {
    func onAppear() async {
        guard let input else { return }

        switch input.source {
        case let .id(id):
            await loadProduct(id: id)
        case let .product(product):
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
