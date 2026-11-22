//
// Copyright © 2026 Alexander Romanov
// DebugTransport.swift, created on 22.11.2026
//

import OversizeArchitecture

public protocol DebugTransport: Sendable {
    func request(_ method: String, params: JSONValue?) async throws -> JSONValue
}
