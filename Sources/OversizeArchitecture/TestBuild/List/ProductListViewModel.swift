//
// Copyright © 2025 Alexander Romanov
// ProductListViewModel.swift, created on 17.09.2025
//

import SwiftUI

@ViewModel
public actor ProductListViewModel: ViewModelProtocol {

    public let state: ProductListViewState
    private let input: ProductListInput?
    private let output: ProductListOutput?

    @MainActor
    public init(state: ProductListViewState, input: ProductListInput?, output: ProductListOutput?) {
        self.state = state
        self.input = input
        self.output = output
    }
    
    func onAppear() async { }
}
