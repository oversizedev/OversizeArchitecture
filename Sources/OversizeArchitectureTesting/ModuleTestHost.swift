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

// MARK: - Introspection

public extension ModuleTestHost where Module.ViewModel.Action: Decodable {
    func send(json actions: String...) async throws {
        for action in actions {
            try await reducer.send(json: action)
        }
    }
}

public extension ModuleTestHost where Module.ViewState: IntrospectableViewState {
    func snapshot() -> JSONValue {
        state.snapshot()
    }
}
