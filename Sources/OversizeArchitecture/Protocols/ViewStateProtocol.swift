//
// Copyright © 2025 Alexander Romanov
// ViewStateProtocol.swift, created on 04.07.2025
//

@MainActor
public protocol ViewStateProtocol: Sendable {
    associatedtype Input

    init(input: Input?)
}

public extension ViewStateProtocol {
    func update(_ handler: @Sendable @MainActor (Self) -> Void) async {
        await MainActor.run { handler(self) }
    }
}
