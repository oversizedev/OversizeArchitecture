//
// Copyright © 2025 Alexander Romanov
// ModuleProtocol.swift, created on 17.09.2025
//

import SwiftUI

public protocol ModuleProtocol {
    associatedtype Input
    associatedtype Output
    associatedtype ViewState: ViewStateProtocol where ViewState.Input == Input
    associatedtype ViewScene: ViewProtocol where ViewScene.ViewState == ViewState, ViewScene.ViewModel == ViewModel
    associatedtype ViewModel: ViewModelProtocol where ViewModel.Input == Input, ViewModel.Output == Output, ViewModel.ViewState == ViewState
}

public extension ModuleProtocol where ViewScene: View {
    @MainActor
    static func build(input: Input? = nil, output: Output? = nil) -> some View {
        ModuleHost<Self>(
            input: input,
            output: output,
            cacheKey: nil
        )
    }

    @MainActor
    static func buildCached(
        cacheKey: String = String(describing: Self.self),
        input: Input? = nil,
        output: Output? = nil
    ) -> some View {
        // `.id(cacheKey)` forces SwiftUI to give the `ModuleHost` a new identity when the
        // key changes, so its `@StateObject` is recreated instead of keeping the previous
        // instance (with stale `input`/`output`) alive under the caller's stable view identity.
        ModuleHost<Self>(
            input: input,
            output: output,
            cacheKey: cacheKey
        )
        .id(cacheKey)
    }
}

// MARK: - Module Lifecycle

@MainActor
private final class ModuleInstance<Module: ModuleProtocol>: ObservableObject where Module.ViewScene: View {
    let viewState: Module.ViewState
    let viewModel: Module.ViewModel
    let reducer: Reducer<Module.ViewModel>

    init(
        input: Module.Input?,
        output: Module.Output?,
        cacheKey: String?
    ) {
        if let cacheKey {
            viewState = ViewStateCache.shared.getOrCreate(key: cacheKey) {
                Module.ViewState(input: input)
            }
        } else {
            viewState = Module.ViewState(input: input)
        }

        viewModel = Module.ViewModel(
            state: viewState,
            input: input,
            output: output
        )
        reducer = Reducer(viewModel: viewModel)
    }
}

private struct ModuleHost<Module: ModuleProtocol>: View where Module.ViewScene: View {
    @StateObject private var instance: ModuleInstance<Module>

    @MainActor
    init(
        input: Module.Input?,
        output: Module.Output?,
        cacheKey: String?
    ) {
        _instance = StateObject(
            wrappedValue: ModuleInstance(
                input: input,
                output: output,
                cacheKey: cacheKey
            )
        )
    }

    var body: some View {
        Module.ViewScene(
            viewState: instance.viewState,
            reducer: instance.reducer
        )
    }
}
