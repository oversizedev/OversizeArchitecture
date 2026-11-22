//
// Copyright © 2026 Alexander Romanov
// DebugCommandLine.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureDebug

public struct DebugCommandLine: Equatable, Sendable {
    public enum Command: Equatable, Sendable {
        case hello
        case list
        case state(module: String)
        case actions(module: String)
        case send(module: String, action: JSONValue)
        case mcp
        case help
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case missingArgument(String)
        case unknownCommand(String)
        case unknownOption(String)
        case invalidPort(String)
        case invalidAction(String)

        public var description: String {
            switch self {
            case let .missingArgument(name):
                "Missing argument: \(name)"
            case let .unknownCommand(command):
                "Unknown command: \(command)"
            case let .unknownOption(option):
                "Unknown option: \(option)"
            case let .invalidPort(value):
                "Invalid port: \(value)"
            case let .invalidAction(value):
                "Action must be a JSON object: \(value)"
            }
        }
    }

    public static let usage = """
    Usage: oversize-debug [--host HOST] [--port PORT] [--token TOKEN] <command>

    Commands:
      hello                      Show the connected app
      list                       List modules on screen
      state <module>             Print a module's ViewState JSON
      actions <module>           List a module's actions
      send <module> <action>     Send an action, e.g. '{"onAppear":{}}'
      mcp                        Run as an MCP server over stdio

    A module is an id or a name. Defaults: host 127.0.0.1, port \(DebugServer.defaultPort).
    Environment: OVERSIZE_DEBUG_HOST, OVERSIZE_DEBUG_PORT, OVERSIZE_DEBUG_TOKEN.
    """

    public var command: Command
    public var host: String
    public var port: UInt16
    public var token: String?

    public init(command: Command, host: String = "127.0.0.1", port: UInt16 = DebugServer.defaultPort, token: String? = nil) {
        self.command = command
        self.host = host
        self.port = port
        self.token = token
    }

    public static func parse(_ arguments: [String], environment: [String: String] = [:]) throws -> DebugCommandLine {
        var host = environment["OVERSIZE_DEBUG_HOST"] ?? "127.0.0.1"
        var port = DebugServer.defaultPort
        if let value = environment["OVERSIZE_DEBUG_PORT"] {
            port = try parsePort(value)
        }
        var token = environment["OVERSIZE_DEBUG_TOKEN"]
        var positional: [String] = []

        var iterator = arguments.makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--host":
                host = try value(after: argument, in: &iterator)
            case "--port":
                port = try parsePort(value(after: argument, in: &iterator))
            case "--token":
                token = try value(after: argument, in: &iterator)
            case "-h", "--help":
                positional = ["help"]
            default:
                guard !argument.hasPrefix("--") else {
                    throw ParseError.unknownOption(argument)
                }
                positional.append(argument)
            }
        }

        let command = try parseCommand(positional)
        return DebugCommandLine(command: command, host: host, port: port, token: token)
    }

    private static func parseCommand(_ positional: [String]) throws -> Command {
        guard let name = positional.first else {
            return .help
        }
        let rest = Array(positional.dropFirst())

        switch name {
        case "hello":
            return .hello
        case "list":
            return .list
        case "state":
            return try .state(module: argument(rest, 0, "module"))
        case "actions":
            return try .actions(module: argument(rest, 0, "module"))
        case "send":
            let module = try argument(rest, 0, "module")
            let text = try argument(rest, 1, "action")
            guard let action = try? JSONDecoder().decode(JSONValue.self, from: Data(text.utf8)), action.isObject else {
                throw ParseError.invalidAction(text)
            }
            return .send(module: module, action: action)
        case "mcp":
            return .mcp
        case "help":
            return .help
        default:
            throw ParseError.unknownCommand(name)
        }
    }

    private static func argument(_ values: [String], _ index: Int, _ name: String) throws -> String {
        guard values.indices.contains(index) else {
            throw ParseError.missingArgument(name)
        }
        return values[index]
    }

    private static func value(after option: String, in iterator: inout IndexingIterator<[String]>) throws -> String {
        guard let value = iterator.next() else {
            throw ParseError.missingArgument(option)
        }
        return value
    }

    private static func parsePort(_ value: String) throws -> UInt16 {
        guard let port = UInt16(value), port > 0 else {
            throw ParseError.invalidPort(value)
        }
        return port
    }

    public var request: (method: DebugMethod, params: JSONValue?)? {
        switch command {
        case .hello:
            (.hello, token.map { ["token": .string($0)] })
        case .list:
            (.listModules, nil)
        case let .state(module):
            (.getState, ["module": .string(module)])
        case let .actions(module):
            (.listActions, ["module": .string(module)])
        case let .send(module, action):
            (.sendAction, ["module": .string(module), "action": action])
        case .mcp, .help:
            nil
        }
    }
}
