//
// Copyright © 2026 Alexander Romanov
// ModuleTestHost.swift, created on 13.11.2026
//

import OversizeArchitecture

@MainActor
public final class ModuleTestHost<Module: ModuleProtocol> {
    public let state: Module.ViewState
    public let viewModel: Module.ViewModel
    public let reducer: Reducer<Module.ViewModel>

    public init(input: Module.Input? = nil, output: Module.Output? = nil) {
        state = Module.ViewState(input: input)
        viewModel = Module.ViewModel(state: state, input: input, output: output)
        reducer = Reducer(viewModel: viewModel)
    }

    public func send(_ actions: Module.ViewModel.Action...) async {
        for action in actions {
            await reducer.send(action)
        }
    }
}
