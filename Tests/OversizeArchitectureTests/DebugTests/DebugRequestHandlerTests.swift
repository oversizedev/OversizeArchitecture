//
// Copyright © 2026 Alexander Romanov
// DebugRequestHandlerTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
@testable import OversizeArchitectureDebug
import OversizeArchitectureTesting
import Testing

@MainActor
struct DebugRequestHandlerTests {
    private let appInfo = DebugAppInfo(
        bundleIdentifier: "com.example.app",
        processName: "Example",
        processIdentifier: 42,
        sessionIdentifier: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
    )

    @Test("Hello describes the app and the protocol")
    func helloDescribesApp() async throws {
        let handler = DebugRequestHandler(registry: ModuleRegistry(), appInfo: appInfo)

        let response = try await send(handler, #"{"jsonrpc":"2.0","id":1,"method":"app.hello"}"#)

        #expect(response.id == 1)
        #expect(response.result?["bundleIdentifier"] == "com.example.app")
        #expect(response.result?["protocolVersion"] == 1)
        #expect(response.result?["methods"] == ["app.hello", "modules.list", "state.get", "actions.list", "action.send"])
    }

    @Test("Lists registered modules with capabilities")
    func listsModules() async throws {
        let registry = ModuleRegistry()
        let log = ModuleTestHost<ActionLog>()
        let detail = ModuleTestHost<ProductDetail>()
        log.register(in: registry)
        detail.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let response = try await send(handler, #"{"id":"list","method":"modules.list"}"#)

        #expect(response.id == "list")
        #expect(response.result == ["modules": [
            [
                "id": .string(log.id.uuidString),
                "name": "ActionLog",
                "stateIntrospectable": true,
                "acceptsActions": true,
                "describesActions": true
            ],
            [
                "id": .string(detail.id.uuidString),
                "name": "ProductDetail",
                "stateIntrospectable": false,
                "acceptsActions": false,
                "describesActions": false
            ]
        ]])
    }

    @Test("Reads state by module id and by name")
    func readsStateByIdAndName() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Debug"))
        host.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let byId = try await send(handler, #"{"id":1,"method":"state.get","params":{"module":"\#(host.id.uuidString)"}}"#)
        let byName = try await send(handler, #"{"id":2,"method":"state.get","params":{"module":"ActionLog"}}"#)

        let expected: JSONValue = ["module": .string(host.id.uuidString), "state": ["title": "Debug", "entries": []]]
        #expect(byId.result == expected)
        #expect(byName.result == expected)
    }

    @Test("Name resolves to the most recently registered module")
    func nameResolvesToLatestModule() async throws {
        let registry = ModuleRegistry()
        let first = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "First"))
        let second = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Second"))
        first.register(in: registry)
        second.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let response = try await send(handler, #"{"id":1,"method":"state.get","params":{"module":"ActionLog"}}"#)

        #expect(response.result?["module"] == .string(second.id.uuidString))
    }

    @Test("Lists action descriptors")
    func listsActionDescriptors() async throws {
        let registry = ModuleRegistry()
        ModuleTestHost<ActionLog>().register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let response = try await send(handler, #"{"id":1,"method":"actions.list","params":{"module":"ActionLog"}}"#)

        #expect(response.result?["actions"] == [
            ["name": "onRecord", "parameters": [["codingKey": "_0", "type": "Int"]]],
            ["name": "onWait", "parameters": []],
            ["name": "onSleep", "parameters": []]
        ])
    }

    @Test("Sends an action and returns the new state")
    func sendsActionAndReturnsState() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Agent"))
        host.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let response = try await send(
            handler,
            #"{"id":7,"method":"action.send","params":{"module":"ActionLog","action":{"onRecord":{"_0":3}}}}"#
        )

        #expect(response.error == nil)
        #expect(response.result?["state"] == ["title": "Agent", "entries": ["record-3"]])
        #expect(await host.viewModel.receivedIndices == [3])
    }

    @Test("Actions sent in sequence enter the ViewModel in order")
    func actionsKeepOrder() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>()
        host.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        for index in 1 ... 3 {
            _ = try await send(
                handler,
                #"{"id":\#(index),"method":"action.send","params":{"module":"ActionLog","action":{"onRecord":{"_0":\#(index)}}}}"#
            )
        }

        #expect(await host.viewModel.receivedIndices == [1, 2, 3])
    }

    @Test("Reports protocol errors with JSON-RPC codes", arguments: [
        (#"not json"#, DebugRPCError.parseErrorCode),
        (#"[1,2]"#, DebugRPCError.invalidRequestCode),
        (#"{"id":1}"#, DebugRPCError.invalidRequestCode),
        (#"{"id":1,"method":"unknown"}"#, DebugRPCError.methodNotFoundCode),
        (#"{"id":1,"method":"state.get"}"#, DebugRPCError.invalidParamsCode),
        (#"{"id":1,"method":"state.get","params":{"module":"Missing"}}"#, DebugRPCError.moduleNotFoundCode),
        (#"{"id":1,"method":"state.get","params":{"module":"ProductDetail"}}"#, DebugRPCError.unsupportedCapabilityCode),
        (#"{"id":1,"method":"actions.list","params":{"module":"ProductDetail"}}"#, DebugRPCError.unsupportedCapabilityCode),
        (#"{"id":1,"method":"action.send","params":{"module":"ProductDetail","action":{"onAppear":{}}}}"#, DebugRPCError.unsupportedCapabilityCode),
        (#"{"id":1,"method":"action.send","params":{"module":"ActionLog","action":"onWait"}}"#, DebugRPCError.invalidParamsCode),
        (#"{"id":1,"method":"action.send","params":{"module":"ActionLog","action":{"onUnknown":{}}}}"#, DebugRPCError.invalidActionCode),
        (#"{"id":1,"method":"action.send","params":{"module":"ActionLog","action":{"onRecord":{"_0":"x"}}}}"#, DebugRPCError.invalidActionCode)
    ])
    func reportsErrors(request: String, code: Int) async throws {
        let registry = ModuleRegistry()
        let log = ModuleTestHost<ActionLog>()
        let detail = ModuleTestHost<ProductDetail>()
        log.register(in: registry)
        detail.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        let response = try await send(handler, request)

        #expect(response.result == nil)
        #expect(response.error?.code == code)
        #expect(await log.viewModel.receivedIndices.isEmpty)
    }

    @Test("Request with a null id still gets a response")
    func nullIdGetsResponse() async throws {
        let handler = DebugRequestHandler(registry: ModuleRegistry(), appInfo: appInfo)

        let response = try await send(handler, #"{"jsonrpc":"2.0","id":null,"method":"modules.list"}"#)

        #expect(response.id == .null)
        #expect(response.result == ["modules": []])
    }

    @Test("Unencodable results become internal errors")
    func unencodableResultsBecomeErrors() throws {
        let data = DebugCoding.encodeResponse(DebugResponse(id: 3, result: ["ratio": .double(.nan)]))

        let response = try JSONDecoder().decode(DebugResponse.self, from: data)

        #expect(response.id == 3)
        #expect(response.error?.code == DebugRPCError.internalErrorCode)
    }

    @Test("Raw action keeps large integers exact")
    func rawActionKeepsLargeIntegers() throws {
        let line = Data(#"{"id":1,"method":"action.send","params":{"action":{"onStore":{"_0":18446744073709551615}}}}"#.utf8)

        let raw = try #require(DebugCoding.rawParameter("action", in: line))
        let decoded = try JSONDecoder().decode([String: [String: UInt64]].self, from: raw)

        #expect(decoded["onStore"]?["_0"] == UInt64.max)
        #expect(DebugCoding.rawParameter("module", in: line) == nil)
    }

    @Test("Notifications get no response")
    func notificationsGetNoResponse() async {
        let handler = DebugRequestHandler(registry: ModuleRegistry(), appInfo: appInfo)

        let response = await handler.handle(Data(#"{"jsonrpc":"2.0","method":"modules.list"}"#.utf8))

        #expect(response == nil)
    }

    @Test("Token protects every method until hello succeeds")
    func tokenProtectsMethods() async throws {
        let handler = DebugRequestHandler(registry: ModuleRegistry(), appInfo: appInfo, token: "secret")

        let beforeHello = try await send(handler, #"{"id":1,"method":"modules.list"}"#)
        let wrongToken = try await send(handler, #"{"id":2,"method":"app.hello","params":{"token":"wrong"}}"#)
        let stillLocked = try await send(handler, #"{"id":3,"method":"modules.list"}"#)
        let hello = try await send(handler, #"{"id":4,"method":"app.hello","params":{"token":"secret"}}"#)
        let afterHello = try await send(handler, #"{"id":5,"method":"modules.list"}"#)
        let repeatedHello = try await send(handler, #"{"id":6,"method":"app.hello"}"#)

        #expect(repeatedHello.result?["bundleIdentifier"] == "com.example.app")
        #expect(beforeHello.error?.code == DebugRPCError.unauthorizedCode)
        #expect(wrongToken.error?.code == DebugRPCError.unauthorizedCode)
        #expect(stillLocked.error?.code == DebugRPCError.unauthorizedCode)
        #expect(hello.error == nil)
        #expect(afterHello.result == ["modules": []])
    }

    @Test("Unregistered module disappears from the protocol")
    func unregisteredModuleDisappears() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>()
        host.register(in: registry)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo)

        host.unregister(from: registry)
        let response = try await send(handler, #"{"id":1,"method":"state.get","params":{"module":"ActionLog"}}"#)

        #expect(response.error?.code == DebugRPCError.moduleNotFoundCode)
    }

    private func send(_ handler: DebugRequestHandler, _ line: String) async throws -> DebugResponse {
        let data = try #require(await handler.handle(Data(line.utf8)))
        return try JSONDecoder().decode(DebugResponse.self, from: data)
    }
}
