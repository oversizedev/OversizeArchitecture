//
// Copyright © 2025 Alexander Romanov
// ViewModelProtocol.swift, created on 04.07.2025
//

public protocol ViewModelProtocol: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    associatedtype Action: Sendable
    associatedtype ViewState: ViewStateProtocol

    init(state: ViewState, input: Input?, output: Output?)

    func handleAction(_ action: Action) async
}
