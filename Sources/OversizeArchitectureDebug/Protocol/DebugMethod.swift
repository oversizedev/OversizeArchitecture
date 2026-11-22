//
// Copyright © 2026 Alexander Romanov
// DebugMethod.swift, created on 22.11.2026
//

public enum DebugMethod: String, CaseIterable, Sendable {
    case hello = "app.hello"
    case listModules = "modules.list"
    case getState = "state.get"
    case listActions = "actions.list"
    case sendAction = "action.send"
}
