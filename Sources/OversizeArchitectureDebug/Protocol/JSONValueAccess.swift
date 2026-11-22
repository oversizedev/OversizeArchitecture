//
// Copyright © 2026 Alexander Romanov
// JSONValueAccess.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture

package extension JSONValue {
    subscript(key: String) -> JSONValue? {
        guard case let .object(object) = self else { return nil }
        return object[key]
    }

    var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    var isObject: Bool {
        if case .object = self {
            return true
        }
        return false
    }

    init(encoding value: some Encodable) throws {
        let data = try JSONEncoder().encode(value)
        self = try JSONDecoder().decode(JSONValue.self, from: data)
    }

    func encodedData(prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes] : [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}

package enum DebugCoding {
    package static func encodeLine(_ value: some Encodable) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }

    package static func encodeResponse(_ response: DebugResponse) -> Data {
        if let data = try? encodeLine(response) {
            return data
        }
        let fallback = DebugResponse(
            id: response.id,
            error: .internalError("The result cannot be encoded as JSON, for example because it contains NaN or infinity")
        )
        return (try? encodeLine(fallback)) ?? Data(#"{"error":{"code":-32603,"message":"Internal error"},"id":null,"jsonrpc":"2.0"}"#.utf8)
    }

    package static func rawParameter(_ name: String, in line: Data) -> Data? {
        guard
            let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
            let params = message["params"] as? [String: Any],
            let value = params[name],
            JSONSerialization.isValidJSONObject(value)
        else {
            return nil
        }
        return try? JSONSerialization.data(withJSONObject: value)
    }
}
