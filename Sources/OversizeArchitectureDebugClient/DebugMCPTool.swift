//
// Copyright © 2026 Alexander Romanov
// DebugMCPTool.swift, created on 22.11.2026
//

import OversizeArchitecture
import OversizeArchitectureDebug

enum DebugMCPTool: String, CaseIterable {
    case appInfo = "app_info"
    case listModules = "list_modules"
    case getState = "get_state"
    case listActions = "list_actions"
    case sendAction = "send_action"

    static let instructions = """
    Drives screens of a running OversizeArchitecture app through data. \
    Call list_modules to see the screens that are on screen now, get_state to read a screen's ViewState as JSON, \
    list_actions to see its actions and send_action to dispatch one. \
    A module is addressed by its id or by its name (the most recently shown screen with that name).
    """

    var method: DebugMethod {
        switch self {
        case .appInfo:
            .hello
        case .listModules:
            .listModules
        case .getState:
            .getState
        case .listActions:
            .listActions
        case .sendAction:
            .sendAction
        }
    }

    var definition: JSONValue {
        .object([
            "name": .string(rawValue),
            "description": .string(description),
            "inputSchema": inputSchema
        ])
    }

    func parameters(from arguments: JSONValue) throws -> JSONValue? {
        switch self {
        case .appInfo, .listModules:
            return nil
        case .getState, .listActions:
            return try .object(["module": module(from: arguments)])
        case .sendAction:
            guard let action = arguments["action"], action.isObject else {
                throw DebugRPCError.invalidParams("'action' must be a JSON object such as {\"onAppear\":{}}")
            }
            return try .object(["module": module(from: arguments), "action": action])
        }
    }

    private func module(from arguments: JSONValue) throws -> JSONValue {
        guard let module = arguments["module"]?.stringValue else {
            throw DebugRPCError.invalidParams("'module' must be a module id or name")
        }
        return .string(module)
    }

    private var description: String {
        switch self {
        case .appInfo:
            "Shows which app is connected: bundle identifier, process and debug protocol version."
        case .listModules:
            "Lists the screens (modules) currently shown in the app with their ids and capabilities."
        case .getState:
            "Returns the JSON snapshot of a module's ViewState."
        case .listActions:
            "Lists the actions a module accepts, with parameter labels, coding keys and Swift types."
        case .sendAction:
            """
            Sends one action to a module, waits until the ViewModel handled it and returns the new state. \
            The action uses Swift's enum coding: {"onAppear":{}}, {"onSelect":{"_0":5}}, {"onRename":{"id":1,"title":"New"}}. \
            Unlabeled parameters use _0, _1 keys.
            """
        }
    }

    private var inputSchema: JSONValue {
        let module: JSONValue = ["type": "string", "description": "Module id or name, for example ProductList"]
        switch self {
        case .appInfo, .listModules:
            return ["type": "object", "properties": [:]]
        case .getState, .listActions:
            return ["type": "object", "properties": ["module": module], "required": ["module"]]
        case .sendAction:
            return [
                "type": "object",
                "properties": [
                    "module": module,
                    "action": ["type": "object", "description": "Action JSON, for example {\"onAppear\":{}}"]
                ],
                "required": ["module", "action"]
            ]
        }
    }
}
