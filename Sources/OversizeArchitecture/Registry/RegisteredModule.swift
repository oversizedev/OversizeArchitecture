//
// Copyright © 2026 Alexander Romanov
// RegisteredModule.swift, created on 22.11.2026
//

import Foundation

@MainActor
public struct RegisteredModule: Identifiable {
    public let id: UUID
    public let name: String
    public let registeredAt: Date
    public let actionDescriptors: [ActionDescriptor]?

    private let snapshotProvider: (@MainActor () throws -> JSONValue)?
    private let actionSender: (@MainActor (Data) async throws -> Void)?

    public var isStateIntrospectable: Bool {
        snapshotProvider != nil
    }

    public var acceptsActions: Bool {
        actionSender != nil
    }

    init<ViewModel: ViewModelProtocol>(
        id: UUID,
        name: String,
        viewState: ViewModel.ViewState,
        reducer: Reducer<ViewModel>,
        registeredAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.registeredAt = registeredAt

        if let introspectableState = viewState as? any IntrospectableViewState {
            if type(of: introspectableState) is AnyClass {
                let stateObject = introspectableState as AnyObject
                snapshotProvider = { [weak stateObject] in
                    guard let state = stateObject as? any IntrospectableViewState else {
                        throw ModuleRegistryError.moduleUnavailable(id)
                    }
                    return state.snapshot()
                }
            } else {
                snapshotProvider = { introspectableState.snapshot() }
            }
        } else {
            snapshotProvider = nil
        }

        actionDescriptors = (ViewModel.Action.self as? any IntrospectableAction.Type)?.descriptors

        if let actionType = ViewModel.Action.self as? any Decodable.Type {
            actionSender = { [weak reducer] json in
                guard let reducer else {
                    throw ModuleRegistryError.moduleUnavailable(id)
                }
                let decoded = try JSONDecoder().decode(actionType, from: json)
                guard let action = decoded as? ViewModel.Action else {
                    throw ModuleRegistryError.actionsNotIntrospectable(id)
                }
                await reducer.send(action)
            }
        } else {
            actionSender = nil
        }
    }

    public func snapshot() throws -> JSONValue {
        guard let snapshotProvider else {
            throw ModuleRegistryError.stateNotIntrospectable(id)
        }
        return try snapshotProvider()
    }

    public func send(json: Data) async throws {
        guard let actionSender else {
            throw ModuleRegistryError.actionsNotIntrospectable(id)
        }
        try await actionSender(json)
    }

    public func send(json: String) async throws {
        try await send(json: Data(json.utf8))
    }
}
