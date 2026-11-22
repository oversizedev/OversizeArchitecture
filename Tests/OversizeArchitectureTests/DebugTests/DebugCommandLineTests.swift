//
// Copyright © 2026 Alexander Romanov
// DebugCommandLineTests.swift, created on 22.11.2026
//

import OversizeArchitecture
import OversizeArchitectureDebug
import OversizeArchitectureDebugClient
import Testing

struct DebugCommandLineTests {
    @Test("Parses commands into protocol requests")
    func parsesCommands() throws {
        let list = try DebugCommandLine.parse(["list"])
        let state = try DebugCommandLine.parse(["state", "ProductList"])
        let send = try DebugCommandLine.parse(["send", "ProductList", #"{"onSelect":{"_0":2}}"#])

        #expect(list.request?.method == .listModules)
        #expect(state.request?.method == .getState)
        #expect(state.request?.params == ["module": "ProductList"])
        #expect(send.command == .send(module: "ProductList", action: ["onSelect": ["_0": 2]]))
        #expect(send.request?.params == ["module": "ProductList", "action": ["onSelect": ["_0": 2]]])
    }

    @Test("Options override the environment")
    func optionsOverrideEnvironment() throws {
        let environment = ["OVERSIZE_DEBUG_PORT": "5000", "OVERSIZE_DEBUG_TOKEN": "env", "OVERSIZE_DEBUG_HOST": "localhost"]

        let fromEnvironment = try DebugCommandLine.parse(["hello"], environment: environment)
        let fromOptions = try DebugCommandLine.parse(["--port", "6000", "--token", "cli", "hello"], environment: environment)

        #expect(fromEnvironment == DebugCommandLine(command: .hello, host: "localhost", port: 5000, token: "env"))
        #expect(fromOptions == DebugCommandLine(command: .hello, host: "localhost", port: 6000, token: "cli"))
        #expect(try DebugCommandLine.parse(["list"]).port == DebugServer.defaultPort)
    }

    @Test("Empty arguments and --help show help")
    func showsHelp() throws {
        #expect(try DebugCommandLine.parse([]).command == .help)
        #expect(try DebugCommandLine.parse(["--help"]).command == .help)
        #expect(try DebugCommandLine.parse(["mcp"]).request == nil)
    }

    @Test("Rejects invalid input")
    func rejectsInvalidInput() {
        #expect(throws: DebugCommandLine.ParseError.missingArgument("module")) {
            try DebugCommandLine.parse(["state"])
        }
        #expect(throws: DebugCommandLine.ParseError.invalidAction("onAppear")) {
            try DebugCommandLine.parse(["send", "ProductList", "onAppear"])
        }
        #expect(throws: DebugCommandLine.ParseError.invalidPort("0")) {
            try DebugCommandLine.parse(["--port", "0", "list"])
        }
        #expect(throws: DebugCommandLine.ParseError.unknownCommand("open")) {
            try DebugCommandLine.parse(["open"])
        }
        #expect(throws: DebugCommandLine.ParseError.unknownOption("--verbose")) {
            try DebugCommandLine.parse(["--verbose", "list"])
        }
    }
}
