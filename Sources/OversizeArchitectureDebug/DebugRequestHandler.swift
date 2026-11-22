//
// Copyright © 2026 Alexander Romanov
// DebugRequestHandler.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture

@MainActor
public final class DebugRequestHandler {
    private let registry: ModuleRegistry
    private let appInfo: DebugAppInfo
    private let token: String?
    private var isAuthorized: Bool

    public init(registry: ModuleRegistry, appInfo: DebugAppInfo = .current(), token: String? = nil) {
        self.registry = registry
        self.appInfo = appInfo
        self.token = token
        isAuthorized = token == nil
    }

    public func handle(_ line: Data) async -> Data? {
        guard let message = try? JSONDecoder().decode(JSONValue.self, from: line) else {
            return encode(DebugResponse(id: nil, error: .parseError()))
        }
        guard message.isObject, let request = try? JSONDecoder().decode(DebugRequest.self, from: line) else {
            return encode(DebugResponse(id: message["id"], error: .invalidRequest()))
        }

        let response: DebugResponse
        do {
            response = try await DebugResponse(id: request.id, result: perform(request, line: line))
        } catch let error as DebugRPCError {
            response = DebugResponse(id: request.id, error: error)
        } catch {
            response = DebugResponse(id: request.id, error: .internalError(String(describing: error)))
        }

        guard request.id != nil else { return nil }
        return encode(response)
    }

    // MARK: - Methods

    private func perform(_ request: DebugRequest, line: Data) async throws -> JSONValue {
        guard let method = DebugMethod(rawValue: request.method) else {
            throw DebugRPCError.methodNotFound(request.method)
        }

        if method == .hello {
            return try hello(params: request.params)
        }

        guard isAuthorized else {
            throw DebugRPCError(code: DebugRPCError.unauthorizedCode, message: "Call app.hello with a valid token first")
        }

        switch method {
        case .hello:
            return try hello(params: request.params)
        case .listModules:
            return .object(["modules": .array(registry.modules.map(summary))])
        case .getState:
            let module = try resolveModule(request.params)
            return try .object(["module": .string(module.id.uuidString), "state": snapshot(of: module)])
        case .listActions:
            let module = try resolveModule(request.params)
            guard let descriptors = module.actionDescriptors else {
                throw unsupported(module, "does not describe its actions")
            }
            return try .object(["module": .string(module.id.uuidString), "actions": JSONValue(encoding: descriptors)])
        case .sendAction:
            return try await sendAction(params: request.params, rawAction: DebugCoding.rawParameter("action", in: line))
        }
    }

    private func hello(params: JSONValue?) throws -> JSONValue {
        if let token {
            if let provided = params?["token"]?.stringValue {
                guard provided == token else {
                    isAuthorized = false
                    throw DebugRPCError(code: DebugRPCError.unauthorizedCode, message: "Invalid token")
                }
                isAuthorized = true
            } else if !isAuthorized {
                throw DebugRPCError(code: DebugRPCError.unauthorizedCode, message: "Token required")
            }
        }
        var info = try JSONValue(encoding: appInfo)
        if case var .object(object) = info {
            object["methods"] = .array(DebugMethod.allCases.map { .string($0.rawValue) })
            info = .object(object)
        }
        return info
    }

    private func sendAction(params: JSONValue?, rawAction: Data?) async throws -> JSONValue {
        let module = try resolveModule(params)
        guard module.acceptsActions else {
            throw unsupported(module, "does not accept JSON actions")
        }
        guard let action = params?["action"], action.isObject else {
            throw DebugRPCError.invalidParams("'action' must be a JSON object such as {\"onAppear\":{}}")
        }

        do {
            try await module.send(json: rawAction ?? action.encodedData())
        } catch let error as DecodingError {
            throw DebugRPCError(
                code: DebugRPCError.invalidActionCode,
                message: "Action does not match \(module.name): \(Self.describe(error))"
            )
        } catch let error as ModuleRegistryError {
            throw Self.rpcError(for: error, module: module)
        }

        let state: JSONValue = module.isStateIntrospectable ? try snapshot(of: module) : .null
        return .object(["module": .string(module.id.uuidString), "state": state])
    }

    // MARK: - Helpers

    private func resolveModule(_ params: JSONValue?) throws -> RegisteredModule {
        guard let reference = params?["module"]?.stringValue else {
            throw DebugRPCError.invalidParams("'module' must be a module id or name")
        }
        if let id = UUID(uuidString: reference), let module = registry.module(id: id) {
            return module
        }
        if let module = registry.modules.last(where: { $0.name == reference }) {
            return module
        }
        throw DebugRPCError(code: DebugRPCError.moduleNotFoundCode, message: "Module not found: \(reference)")
    }

    private func snapshot(of module: RegisteredModule) throws -> JSONValue {
        do {
            return try module.snapshot()
        } catch let error as ModuleRegistryError {
            throw Self.rpcError(for: error, module: module)
        }
    }

    private func summary(of module: RegisteredModule) -> JSONValue {
        .object([
            "id": .string(module.id.uuidString),
            "name": .string(module.name),
            "stateIntrospectable": .bool(module.isStateIntrospectable),
            "acceptsActions": .bool(module.acceptsActions),
            "describesActions": .bool(module.actionDescriptors != nil)
        ])
    }

    private func unsupported(_ module: RegisteredModule, _ reason: String) -> DebugRPCError {
        DebugRPCError(code: DebugRPCError.unsupportedCapabilityCode, message: "\(module.name) \(reason)")
    }

    private static func rpcError(for error: ModuleRegistryError, module: RegisteredModule) -> DebugRPCError {
        switch error {
        case .moduleNotFound:
            DebugRPCError(code: DebugRPCError.moduleNotFoundCode, message: "Module not found: \(module.id.uuidString)")
        case .moduleUnavailable:
            DebugRPCError(code: DebugRPCError.moduleUnavailableCode, message: "\(module.name) is no longer alive")
        case .stateNotIntrospectable:
            DebugRPCError(code: DebugRPCError.unsupportedCapabilityCode, message: "\(module.name) state is not introspectable")
        case .actionsNotIntrospectable:
            DebugRPCError(code: DebugRPCError.unsupportedCapabilityCode, message: "\(module.name) does not accept JSON actions")
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case let .typeMismatch(_, context), let .valueNotFound(_, context),
             let .keyNotFound(_, context), let .dataCorrupted(context):
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            return path.isEmpty ? context.debugDescription : "\(path): \(context.debugDescription)"
        @unknown default:
            return String(describing: error)
        }
    }

    private func encode(_ response: DebugResponse) -> Data {
        DebugCoding.encodeResponse(response)
    }
}
