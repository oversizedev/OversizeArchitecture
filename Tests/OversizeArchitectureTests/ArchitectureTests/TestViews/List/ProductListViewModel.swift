//
// Copyright © 2025 Alexander Romanov
// ProductListViewModel.swift, created on 17.09.2025
//

import SwiftUI
@testable import OversizeArchitecture

@ViewModel
public actor ProductListViewModel: ViewModelProtocol {

    public let state: ProductListModule.ViewState
    private let input: ProductListModule.Input?
    private let output: ProductListModule.Output?

    @MainActor
    public init(state: ProductListModule.ViewState, input: ProductListModule.Input?, output: ProductListModule.Output?) {
        self.state = state
        self.input = input
        self.output = output
    }
    
    func onAppear() async { }
}
