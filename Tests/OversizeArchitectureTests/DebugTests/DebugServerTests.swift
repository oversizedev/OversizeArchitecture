//
// Copyright © 2026 Alexander Romanov
// DebugServerTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
import OversizeArchitectureDebug
import OversizeArchitectureDebugClient
import OversizeArchitectureTesting
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct DebugServerTests {
    @Test("Server is available in debug builds")
    func serverIsAvailable() {
        #expect(DebugServer.isAvailable)
    }

    @Test("Client drives a module through a loopback socket")
    func clientDrivesModuleOverSocket() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Socket"))
        host.register(in: registry)
        let server = DebugServer(registry: registry, configuration: DebugServer.Configuration(port: 0))
        let port = try await server.start()
        defer { server.stop() }
        let client = DebugClient(configuration: DebugClient.Configuration(port: port, timeout: .seconds(10)))

        let modules = try await client.request(DebugMethod.listModules.rawValue, params: nil)
        let sent = try await client.request(
            DebugMethod.sendAction.rawValue,
            params: ["module": "ActionLog", "action": ["onRecord": ["_0": 6]]]
        )
        let state = try await client.request(DebugMethod.getState.rawValue, params: ["module": .string(host.id.uuidString)])
        await client.close()

        #expect(port > 0)
        #expect(server.port == port)
        #expect(modules["modules"] == [[
            "id": .string(host.id.uuidString),
            "name": "ActionLog",
            "stateIntrospectable": true,
            "acceptsActions": true,
            "describesActions": true
        ]])
        #expect(sent["state"] == ["title": "Socket", "entries": ["record-6"]])
        #expect(state["state"] == ["title": "Socket", "entries": ["record-6"]])
        #expect(await client.appInfo?["protocolVersion"] == 1)
    }

    @Test("Remote errors reach the client")
    func remoteErrorsReachClient() async throws {
        let server = DebugServer(registry: ModuleRegistry(), configuration: DebugServer.Configuration(port: 0))
        let port = try await server.start()
        defer { server.stop() }
        let client = DebugClient(configuration: DebugClient.Configuration(port: port, timeout: .seconds(10)))

        await #expect(throws: DebugRPCError.self) {
            try await client.request(DebugMethod.getState.rawValue, params: ["module": "Missing"])
        }
        let modules = try await client.request(DebugMethod.listModules.rawValue, params: nil)
        await client.close()

        #expect(modules == ["modules": []])
    }

    @Test("Token is required when configured")
    func tokenIsRequired() async throws {
        let server = DebugServer(
            registry: ModuleRegistry(),
            configuration: DebugServer.Configuration(port: 0, token: "secret")
        )
        let port = try await server.start()
        defer { server.stop() }
        let anonymous = DebugClient(configuration: DebugClient.Configuration(port: port, timeout: .seconds(10)))
        let authorized = DebugClient(configuration: DebugClient.Configuration(port: port, token: "secret", timeout: .seconds(10)))

        await #expect(throws: DebugRPCError.self) {
            try await anonymous.request(DebugMethod.listModules.rawValue, params: nil)
        }
        let modules = try await authorized.request(DebugMethod.listModules.rawValue, params: nil)
        await anonymous.close()
        await authorized.close()

        #expect(modules == ["modules": []])
    }

    @Test("Cancelling a pending request frees the client")
    func cancellingPendingRequestFreesClient() async throws {
        let registry = ModuleRegistry()
        let gate = ActionLogGate()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Gate", gate: gate))
        host.register(in: registry)
        let server = DebugServer(registry: registry, configuration: DebugServer.Configuration(port: 0))
        let port = try await server.start()
        defer { server.stop() }
        let client = DebugClient(configuration: DebugClient.Configuration(port: port, timeout: .seconds(30)))
        _ = try await client.request(DebugMethod.listModules.rawValue, params: nil)

        let pending = Task {
            try await client.request(DebugMethod.sendAction.rawValue, params: ["module": "ActionLog", "action": ["onWait": [:]]])
        }
        try await Task.sleep(for: .milliseconds(100))
        pending.cancel()

        await #expect(throws: (any Error).self) {
            try await pending.value
        }
        let modules = try await client.request(DebugMethod.listModules.rawValue, params: nil)
        await gate.open()
        await client.close()

        #expect(modules["modules"] != nil)
    }

    @Test("Starting twice throws")
    func startingTwiceThrows() async throws {
        let server = DebugServer(registry: ModuleRegistry(), configuration: DebugServer.Configuration(port: 0))
        _ = try await server.start()
        defer { server.stop() }

        await #expect(throws: DebugServerError.alreadyStarted) {
            try await server.start()
        }
    }

    @Test("Client reports a closed port")
    func clientReportsClosedPort() async throws {
        let server = DebugServer(registry: ModuleRegistry(), configuration: DebugServer.Configuration(port: 0))
        let port = try await server.start()
        server.stop()
        let client = DebugClient(configuration: DebugClient.Configuration(port: port, timeout: .seconds(5)))

        await #expect(throws: DebugClientError.self) {
            try await client.request(DebugMethod.listModules.rawValue, params: nil)
        }
    }
}
