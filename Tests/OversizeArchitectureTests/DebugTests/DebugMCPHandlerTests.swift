//
// Copyright © 2026 Alexander Romanov
// DebugMCPHandlerTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
import OversizeArchitectureDebug
import OversizeArchitectureDebugClient
import OversizeArchitectureTesting
import Testing

@MainActor
struct DebugMCPHandlerTests {
    @Test("Initialize negotiates a supported protocol version")
    func initializeNegotiatesVersion() async throws {
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: ModuleRegistry()))

        let supported = try await send(handler, #"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}"#)
        let unknown = try await send(handler, #"{"jsonrpc":"2.0","id":2,"method":"initialize","params":{"protocolVersion":"1999-01-01"}}"#)

        #expect(supported.result?["protocolVersion"] == "2025-06-18")
        #expect(supported.result?["serverInfo"]?["name"] == "oversize-debug")
        #expect(supported.result?["capabilities"]?["tools"] != nil)
        #expect(unknown.result?["protocolVersion"] == .string(DebugMCPHandler.supportedProtocolVersions[0]))
    }

    @Test("Initialized notification and ping")
    func notificationsAndPing() async throws {
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: ModuleRegistry()))

        let notification = await handler.handle(Data(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#.utf8))
        let ping = try await send(handler, #"{"jsonrpc":"2.0","id":"p","method":"ping"}"#)

        #expect(notification == nil)
        #expect(ping.result == [:])
    }

    @Test("Lists tools with input schemas")
    func listsTools() async throws {
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: ModuleRegistry()))

        let response = try await send(handler, #"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#)

        guard case let .array(tools)? = response.result?["tools"] else {
            Issue.record("Missing tools")
            return
        }
        #expect(tools.compactMap { $0["name"]?.stringValue } == ["app_info", "list_modules", "get_state", "list_actions", "send_action"])
        #expect(tools.allSatisfy { $0["inputSchema"]?["type"] == "object" })
        #expect(tools[4]["inputSchema"]?["required"] == ["module", "action"])
    }

    @Test("send_action drives the module and returns structured state")
    func sendActionTool() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "MCP"))
        host.register(in: registry)
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: registry))

        let response = try await send(
            handler,
            #"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"send_action","arguments":{"module":"ActionLog","action":{"onRecord":{"_0":8}}}}}"#
        )

        #expect(response.result?["isError"] == false)
        #expect(response.result?["structuredContent"]?["state"] == ["title": "MCP", "entries": ["record-8"]])
        guard case let .array(content)? = response.result?["content"], let text = content.first?["text"]?.stringValue else {
            Issue.record("Missing text content")
            return
        }
        #expect(text.contains("record-8"))
        #expect(await host.viewModel.receivedIndices == [8])
    }

    @Test("App errors become tool errors")
    func appErrorsBecomeToolErrors() async throws {
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: ModuleRegistry()))

        let response = try await send(
            handler,
            #"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"get_state","arguments":{"module":"Missing"}}}"#
        )

        #expect(response.error == nil)
        #expect(response.result?["isError"] == true)
        #expect(response.result?["structuredContent"] == nil)
    }

    @Test("Bad tool calls are JSON-RPC errors")
    func badToolCalls() async throws {
        let handler = DebugMCPHandler(transport: HandlerTransport(registry: ModuleRegistry()))

        let unknownTool = try await send(handler, #"{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"nope"}}"#)
        let missingModule = try await send(handler, #"{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"get_state","arguments":{}}}"#)
        let unknownMethod = try await send(handler, #"{"jsonrpc":"2.0","id":7,"method":"resources/list"}"#)

        #expect(unknownTool.error?.code == DebugRPCError.invalidParamsCode)
        #expect(missingModule.result?["isError"] == true)
        #expect(unknownMethod.error?.code == DebugRPCError.methodNotFoundCode)
    }

    private func send(_ handler: DebugMCPHandler, _ line: String) async throws -> DebugResponse {
        let data = try #require(await handler.handle(Data(line.utf8)))
        return try JSONDecoder().decode(DebugResponse.self, from: data)
    }
}

private struct HandlerTransport: DebugTransport {
    let handler: DebugRequestHandler

    @MainActor
    init(registry: ModuleRegistry) {
        handler = DebugRequestHandler(registry: registry)
    }

    func request(_ method: String, params: JSONValue?) async throws -> JSONValue {
        let line = try JSONEncoder().encode(DebugRequest(id: 1, method: method, params: params))
        guard let data = await handler.handle(line) else {
            throw DebugRPCError.internalError("No response")
        }
        let response = try JSONDecoder().decode(DebugResponse.self, from: data)
        if let error = response.error {
            throw error
        }
        return response.result ?? .null
    }
}
