//
// Copyright © 2026 Alexander Romanov
// ReducerIntrospection.swift, created on 22.11.2026
//

import Foundation

public extension Reducer where ViewModel.Action: Decodable {
    func send(json: Data) async throws {
        let action = try JSONDecoder().decode(ViewModel.Action.self, from: json)
        await send(action)
    }

    func send(json: String) async throws {
        try await send(json: Data(json.utf8))
    }
}
