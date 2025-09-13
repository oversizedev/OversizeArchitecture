//
// Copyright © 2025 Alexander Romanov
// ViewStateProtocol.swift, created on 04.07.2025
//

import SwiftUI

// MARK: - ViewState

@MainActor
public protocol ViewStateProtocol: Sendable {}

public extension ViewStateProtocol {
    func update(_ handler: @Sendable @MainActor (Self) -> Void) async {
        await MainActor.run { handler(self) }
    }
}
