//
// Copyright © 2026 Alexander Romanov
// IntrospectableViewState.swift, created on 22.11.2026
//

import Foundation

@MainActor
public protocol IntrospectableViewState: ViewStateProtocol {
    func snapshot() -> JSONValue
}

public extension IntrospectableViewState {
    func snapshot() -> JSONValue {
        StateReflector().reflect(self)
    }

    func snapshotJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(snapshot())
    }
}
