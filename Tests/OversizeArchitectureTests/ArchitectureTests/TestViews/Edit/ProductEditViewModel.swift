//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModel.swift, created on 17.09.2025
//

@testable import OversizeArchitecture
import SwiftUI

@ViewModel(module: ProductEditModule.self)
public actor ProductEditViewModel: ViewModelProtocol {
    func onAppear() async {}

    func onTapSave() async {
        let product = await Product(id: state.productId, name: state.name)
        output?.onSave(product)
    }
}
