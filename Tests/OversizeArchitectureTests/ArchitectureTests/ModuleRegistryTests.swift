//
// Copyright © 2026 Alexander Romanov
// ModuleRegistryTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
import OversizeArchitectureTesting
import Testing

@MainActor
struct ModuleRegistryTests {
    @Test("Registry is available in debug builds")
    func registryIsAvailableInDebug() {
        #expect(ModuleRegistry.isAvailable)
    }

    @Test("Registers modules in order with their names")
    func registersModulesInOrder() {
        let registry = ModuleRegistry()
        let log = ModuleTestHost<ActionLog>()
        let detail = ModuleTestHost<ProductDetail>()

        log.register(in: registry)
        detail.register(in: registry)

        #expect(registry.modules.map(\.id) == [log.id, detail.id])
        #expect(registry.modules.map(\.name) == ["ActionLog", "ProductDetail"])
    }

    @Test("Registering the same instance twice keeps one entry")
    func registeringTwiceIsIdempotent() {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>()

        host.register(in: registry)
        host.register(in: registry)

        #expect(registry.modules.count == 1)
    }

    @Test("Unregister removes only that instance")
    func unregisterRemovesOnlyThatInstance() {
        let registry = ModuleRegistry()
        let first = ModuleTestHost<ActionLog>()
        let second = ModuleTestHost<ActionLog>()
        first.register(in: registry)
        second.register(in: registry)

        first.unregister(from: registry)

        #expect(registry.modules.map(\.id) == [second.id])
        #expect(registry.module(id: first.id) == nil)
    }

    @Test("Introspectable module exposes snapshot and descriptors")
    func introspectableModuleExposesCapabilities() throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Registry"))
        host.register(in: registry)

        let module = try #require(registry.module(id: host.id))

        #expect(module.isStateIntrospectable)
        #expect(module.acceptsActions)
        #expect(module.actionDescriptors == ActionLog.ViewModel.Action.descriptors)
        #expect(try module.snapshot() == ["title": "Registry", "entries": []])
    }

    @Test("JSON action sent through the registry updates the snapshot")
    func jsonActionUpdatesSnapshot() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Agent"))
        host.register(in: registry)

        try await registry.send(json: Data(#"{"onRecord":{"_0":4}}"#.utf8), to: host.id)

        #expect(try registry.snapshot(of: host.id) == ["title": "Agent", "entries": ["record-4"]])
        #expect(await host.viewModel.receivedIndices == [4])
    }

    @Test("Plain module has no snapshot and rejects actions")
    func plainModuleRejectsIntrospection() async throws {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ProductDetail>()
        host.register(in: registry)
        let module = try #require(registry.module(id: host.id))

        #expect(!module.isStateIntrospectable)
        #expect(!module.acceptsActions)
        #expect(module.actionDescriptors == nil)
        #expect(throws: ModuleRegistryError.stateNotIntrospectable(host.id)) {
            try module.snapshot()
        }
        await #expect(throws: ModuleRegistryError.actionsNotIntrospectable(host.id)) {
            try await module.send(json: #"{"onAppear":{}}"#)
        }
    }

    @Test("Decodable actions without descriptors can still be sent")
    func decodableActionsWithoutDescriptors() async throws {
        let state = ActionLogViewState(input: nil)
        let reducer = Reducer(viewModel: DecodableActionViewModel(state: state, input: nil, output: nil))
        let module = RegisteredModule(id: UUID(), name: "Decodable", viewState: state, reducer: reducer)

        #expect(module.acceptsActions)
        #expect(module.actionDescriptors == nil)

        try await module.send(json: #"{"record":{"_0":2}}"#)

        #expect(try module.snapshot() == ["title": "Log", "entries": ["decoded-2"]])
    }

    @Test("Unknown module id throws")
    func unknownModuleThrows() async {
        let registry = ModuleRegistry()
        let id = UUID()

        #expect(throws: ModuleRegistryError.moduleNotFound(id)) {
            try registry.snapshot(of: id)
        }
        await #expect(throws: ModuleRegistryError.moduleNotFound(id)) {
            try await registry.send(json: Data("{}".utf8), to: id)
        }
    }

    @Test("Invalid action JSON throws and dispatches nothing")
    func invalidActionJSONThrows() async {
        let registry = ModuleRegistry()
        let host = ModuleTestHost<ActionLog>()
        host.register(in: registry)

        await #expect(throws: DecodingError.self) {
            try await registry.send(json: Data(#"{"onUnknown":{}}"#.utf8), to: host.id)
        }

        #expect(await host.viewModel.receivedIndices.isEmpty)
    }

    @Test("Registry does not keep the module alive")
    func registryDoesNotRetainModule() async throws {
        let registry = ModuleRegistry()
        var id: UUID?
        weak var weakReducer: Reducer<ActionLog.ViewModel>?
        weak var weakState: ActionLogViewState?
        do {
            let host = ModuleTestHost<ActionLog>()
            host.register(in: registry)
            id = host.id
            weakReducer = host.reducer
            weakState = host.state
        }
        let moduleId = try #require(id)

        #expect(weakReducer == nil)
        #expect(weakState == nil)
        #expect(throws: ModuleRegistryError.moduleUnavailable(moduleId)) {
            try registry.snapshot(of: moduleId)
        }
        await #expect(throws: ModuleRegistryError.moduleUnavailable(moduleId)) {
            try await registry.send(json: Data(#"{"onWait":{}}"#.utf8), to: moduleId)
        }
    }
}
