//
// Copyright © 2026 Alexander Romanov
// AsyncCallback.swift, created on 18.05.2026
//

import SwiftUI

public struct AsyncCallback<Value>: Hashable, Equatable, Sendable {
    public let identifier: String
    public let handler: @Sendable (Value) async throws -> Void

    public init(_ identifier: String = UUID().uuidString, handler: @Sendable @escaping (Value) async throws -> Void) {
        self.identifier = identifier
        self.handler = handler
    }

    public func callAsFunction(_ value: Value) async throws {
        try await handler(value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: AsyncCallback<Value>, rhs: AsyncCallback<Value>) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
