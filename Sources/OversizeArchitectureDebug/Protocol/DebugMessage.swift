//
// Copyright © 2026 Alexander Romanov
// DebugMessage.swift, created on 22.11.2026
//

import OversizeArchitecture

public struct DebugRequest: Codable, Sendable, Equatable {
    public let jsonrpc: String
    public let id: JSONValue?
    public let method: String
    public let params: JSONValue?

    public init(id: JSONValue?, method: String, params: JSONValue? = nil) {
        jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc) ?? "2.0"
        id = try Self.decodeIdentifier(from: container)
        method = try container.decode(String.self, forKey: .method)
        params = try container.decodeIfPresent(JSONValue.self, forKey: .params)
    }
}

extension DebugRequest {
    static func decodeIdentifier<Key: CodingKey>(from container: KeyedDecodingContainer<Key>) throws -> JSONValue? {
        guard let key = Key(stringValue: "id"), container.contains(key) else {
            return Optional<JSONValue>.none
        }
        return try container.decode(JSONValue.self, forKey: key)
    }
}

public struct DebugResponse: Codable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case jsonrpc
        case id
        case result
        case error
    }

    public let jsonrpc: String
    public let id: JSONValue?
    public let result: JSONValue?
    public let error: DebugRPCError?

    public init(id: JSONValue?, result: JSONValue) {
        jsonrpc = "2.0"
        self.id = id
        self.result = result
        error = nil
    }

    public init(id: JSONValue?, error: DebugRPCError) {
        jsonrpc = "2.0"
        self.id = id
        result = nil
        self.error = error
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        jsonrpc = try container.decodeIfPresent(String.self, forKey: .jsonrpc) ?? "2.0"
        id = try DebugRequest.decodeIdentifier(from: container)
        result = try container.decodeIfPresent(JSONValue.self, forKey: .result)
        error = try container.decodeIfPresent(DebugRPCError.self, forKey: .error)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id ?? .null, forKey: .id)
        try container.encodeIfPresent(result, forKey: .result)
        try container.encodeIfPresent(error, forKey: .error)
    }
}

public struct DebugRPCError: Error, Codable, Sendable, Equatable {
    public let code: Int
    public let message: String
    public let data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public extension DebugRPCError {
    static let parseErrorCode = -32700
    static let invalidRequestCode = -32600
    static let methodNotFoundCode = -32601
    static let invalidParamsCode = -32602
    static let internalErrorCode = -32603
    static let moduleNotFoundCode = -32001
    static let moduleUnavailableCode = -32002
    static let unsupportedCapabilityCode = -32003
    static let invalidActionCode = -32004
    static let unauthorizedCode = -32005

    static func parseError(_ message: String = "Parse error") -> DebugRPCError {
        DebugRPCError(code: parseErrorCode, message: message)
    }

    static func invalidRequest(_ message: String = "Invalid request") -> DebugRPCError {
        DebugRPCError(code: invalidRequestCode, message: message)
    }

    static func methodNotFound(_ method: String) -> DebugRPCError {
        DebugRPCError(code: methodNotFoundCode, message: "Method not found: \(method)")
    }

    static func invalidParams(_ message: String) -> DebugRPCError {
        DebugRPCError(code: invalidParamsCode, message: message)
    }

    static func internalError(_ message: String) -> DebugRPCError {
        DebugRPCError(code: internalErrorCode, message: message)
    }
}
