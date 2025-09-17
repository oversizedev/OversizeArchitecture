//
// Copyright © 2025 Alexander Romanov
// ModuleProtocol.swift, created on 17.09.2025
//  

import SwiftUI

protocol ModuleProtocol {
    associatedtype Input
    associatedtype Output
    associatedtype ViewState: ViewStateProtocol where ViewState.Input == Input
    associatedtype ViewScene: ViewProtocol where ViewScene.ViewState == ViewState, ViewScene.ViewModel == ViewModel
    associatedtype ViewModel: ViewModelProtocol where ViewModel.Input == Input, ViewModel.Output == Output, ViewModel.ViewState == ViewState
}

extension ModuleProtocol where ViewScene: View {
    @MainActor
    static func preview(input: Input? = nil, output: Output? = nil) -> some View {
        let state = ViewState(input: input)
        let viewModel = ViewModel(
            state: state,
            input: input,
            output: output
        )
        let reducer = Reducer(viewModel: viewModel)
        return ViewScene(viewState: state, reducer: reducer)
    }
}

final class Builder<M>: Sendable where M: ModuleProtocol, M.ViewScene: View { }

extension Builder where M.ViewScene: View {
    @MainActor
    static func build(input: M.ViewModel.Input? = nil, output: M.ViewModel.Output? = nil) -> some View {
        let state = M.ViewState(input: input)
        let viewModel = M.ViewModel(
            state: state,
            input: input,
            output: output
        )
        let reducer = Reducer(viewModel: viewModel)
        return M.ViewScene(viewState: state, reducer: reducer)
    }
}
