//
// Copyright © 2025 Alexander Romanov
// Reducer.swift, created on 04.07.2025
//

import Foundation
import OversizeCore

public final class Reducer<ViewModel>: Sendable where ViewModel: ViewModelProtocol {
    private let viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public func callAsFunction(_ action: ViewModel.Action) {
        Task {
            logUI(String(describing: action))
            await self.viewModel.handleAction(action)
        }
    }
}
