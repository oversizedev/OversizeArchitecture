//
// Copyright © 2025 Alexander Romanov
// ViewModelProtocol.swift, created on 04.07.2025
//

public protocol ViewModelProtocol: Sendable {
    associatedtype Action: Sendable
    associatedtype ViewState: ViewStateProtocol

    @MainActor
    init(state: ViewState)

    func handleAction(_ action: Action) async
}
