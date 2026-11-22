//
// Copyright © 2026 Alexander Romanov
// DecodableActionViewModel.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture

actor DecodableActionViewModel: ViewModelProtocol {
    enum Action: Codable, Sendable {
        case record(Int)
    }

    let state: ActionLogViewState

    init(state: ActionLogViewState, input _: ActionLogInput?, output _: ActionLogOutput?) {
        self.state = state
    }

    func handleAction(_ action: Action) async {
        switch action {
        case let .record(index):
            await state.update { state in
                state.entries.append("decoded-\(index)")
            }
        }
    }
}
