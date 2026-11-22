//
// Copyright © 2026 Alexander Romanov
// ModuleRegistry.swift, created on 22.11.2026
//

import Foundation

@MainActor
public final class ModuleRegistry {
    public static var isAvailable: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private var entries: [UUID: RegisteredModule] = [:]
    private var order: [UUID] = []

    public init() {}

    public var modules: [RegisteredModule] {
        order.compactMap { entries[$0] }
    }

    public func module(id: UUID) -> RegisteredModule? {
        entries[id]
    }

    public func register<Module: ModuleProtocol>(
        _: Module.Type,
        id: UUID,
        viewState: Module.ViewState,
        reducer: Reducer<Module.ViewModel>
    ) {
        #if DEBUG
        guard entries[id] == nil else { return }
        entries[id] = RegisteredModule(
            id: id,
            name: String(describing: Module.self),
            viewState: viewState,
            reducer: reducer
        )
        order.append(id)
        #endif
    }

    public func unregister(id: UUID) {
        guard entries.removeValue(forKey: id) != nil else { return }
        order.removeAll { $0 == id }
    }

    public func removeAll() {
        entries.removeAll()
        order.removeAll()
    }

    public func snapshot(of id: UUID) throws -> JSONValue {
        try requireModule(id).snapshot()
    }

    public func send(json: Data, to id: UUID) async throws {
        try await requireModule(id).send(json: json)
    }

    private func requireModule(_ id: UUID) throws -> RegisteredModule {
        guard let module = entries[id] else {
            throw ModuleRegistryError.moduleNotFound(id)
        }
        return module
    }
}
