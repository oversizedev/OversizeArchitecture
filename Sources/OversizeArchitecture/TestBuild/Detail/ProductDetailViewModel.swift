//
// Copyright © 2025 Alexander Romanov
// MealProductDetailViewModel.swift, created on 10.07.2025
//

import SwiftUI

@ViewModel
public actor ProductDetailViewModel: ViewModelProtocol {

    public var state: ProductDetailModule.ViewState
    private let input: ProductDetailModule.Input?
    private let output: ProductDetailModule.Output?
    
    public init(state: ProductDetailModule.ViewState, input: ProductDetailModule.Input?, output: ProductDetailModule.Output?) {
        self.state = state
        self.input = input
        self.output = output
    }

    func onAppear() async { }
}
