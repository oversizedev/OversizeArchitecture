//
// Copyright © 2026 Alexander Romanov
// DebugMCPHandler.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureDebug

public struct DebugMCPHandler: Sendable {
    public static let supportedProtocolVersions = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"]
    public static let serverName = "oversize-debug"
    public static let serverVersion = "1.0.0"

    private let transport: any DebugTransport

    public init(transport: any DebugTransport) {
        self.transport = transport
    }

    public func handle(_ line: Data) async -> Data? {
        guard let message = try? JSONDecoder().decode(JSONValue.self, from: line) else {
            return encode(DebugResponse(id: nil, error: .parseError()))
        }
        guard message.isObject, let request = try? JSONDecoder().decode(DebugRequest.self, from: line) else {
            return encode(DebugResponse(id: message["id"], error: .invalidRequest()))
        }
        guard let id = request.id else {
            return nil
        }

        do {
            return try await encode(DebugResponse(id: id, result: perform(request)))
        } catch let error as DebugRPCError {
            return encode(DebugResponse(id: id, error: error))
        } catch {
            return encode(DebugResponse(id: id, error: .internalError(String(describing: error))))
        }
    }

    // MARK: - Methods

    private func perform(_ request: DebugRequest) async throws -> JSONValue {
        switch request.method {
        case "initialize":
            initialize(params: request.params)
        case "ping":
            .object([:])
        case "tools/list":
            .object(["tools": .array(DebugMCPTool.allCases.map(\.definition))])
        case "tools/call":
            try await callTool(params: request.params)
        default:
            throw DebugRPCError.methodNotFound(request.method)
        }
    }

    private func initialize(params: JSONValue?) -> JSONValue {
        let requested = params?["protocolVersion"]?.stringValue
        let version = requested.flatMap { Self.supportedProtocolVersions.contains($0) ? $0 : nil }
            ?? Self.supportedProtocolVersions[0]
        return .object([
            "protocolVersion": .string(version),
            "capabilities": .object(["tools": .object(["listChanged": false])]),
            "serverInfo": .object(["name": .string(Self.serverName), "version": .string(Self.serverVersion)]),
            "instructions": .string(DebugMCPTool.instructions)
        ])
    }

    private func callTool(params: JSONValue?) async throws -> JSONValue {
        guard let name = params?["name"]?.stringValue else {
            throw DebugRPCError.invalidParams("'name' is required")
        }
        guard let tool = DebugMCPTool(rawValue: name) else {
            throw DebugRPCError.invalidParams("Unknown tool: \(name)")
        }

        let arguments = params?["arguments"] ?? .object([:])
        do {
            let result = try await transport.request(tool.method.rawValue, params: tool.parameters(from: arguments))
            return try toolResult(text: String(decoding: result.encodedData(prettyPrinted: true), as: UTF8.self), structured: result)
        } catch let error as DebugRPCError {
            return try toolResult(text: "Error \(error.code): \(error.message)", isError: true)
        } catch {
            return try toolResult(text: String(describing: error), isError: true)
        }
    }

    private func toolResult(text: String, structured: JSONValue? = nil, isError: Bool = false) throws -> JSONValue {
        var result: [String: JSONValue] = [
            "content": .array([.object(["type": "text", "text": .string(text)])]),
            "isError": .bool(isError)
        ]
        if let structured, structured.isObject {
            result["structuredContent"] = structured
        }
        return .object(result)
    }

    private func encode(_ response: DebugResponse) -> Data {
        DebugCoding.encodeResponse(response)
    }
}
