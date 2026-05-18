//
// Copyright © 2025 Alexander Romanov
// Callback.swift, created on 17.09.2025
//

import Foundation

public struct Callback<Value>: Hashable, Sendable {
    
    public let identifier: String
    public let handler: @Sendable (Value) -> Void

    public init(_ identifier: String = UUID().uuidString, handler: @Sendable @escaping (Value) -> Void) {
        self.identifier = identifier
        self.handler = handler
    }

    public func callAsFunction(_ value: Value) {
        handler(value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: Callback<Value>, rhs: Callback<Value>) -> Bool {
        lhs.identifier == rhs.identifier
    }
}
