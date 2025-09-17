//
// Copyright © 2025 Alexander Romanov
// MealProductDetailViewModel.swift, created on 10.07.2025
//

import SwiftUI

@ViewModel
public actor ProductDetailViewModel: ViewModelProtocol {

    public var state: ProductDetailViewState
    private let input: ProductDetailInput?
    private let output: ProductDetailOutput?
    
    public init(state: ProductDetailViewState, input: ProductDetailInput?, output: ProductDetailOutput?) {
        self.state = state
        self.input = input
        self.output = output
    }

    func onAppear() async { }
}
