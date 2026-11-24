//
// Copyright © 2026 Alexander Romanov
// JSONValue.swift, created on 22.11.2026
//

public enum JSONValue: Sendable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
}

// MARK: - Equality

extension JSONValue: Hashable {
    public static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null):
            true
        case let (.bool(left), .bool(right)):
            left == right
        case let (.int(left), .int(right)):
            left == right
        case let (.double(left), .double(right)):
            left == right
        case let (.int(left), .double(right)), let (.double(right), .int(left)):
            Double(left) == right && Int(exactly: right) == left
        case let (.string(left), .string(right)):
            left == right
        case let (.array(left), .array(right)):
            left == right
        case let (.object(left), .object(right)):
            left == right
        default:
            false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .null:
            hasher.combine(0)
        case let .bool(value):
            hasher.combine(1)
            hasher.combine(value)
        case let .int(value):
            hasher.combine(2)
            hasher.combine(value)
        case let .double(value):
            if let integer = Int(exactly: value) {
                hasher.combine(2)
                hasher.combine(integer)
            } else {
                hasher.combine(3)
                hasher.combine(value)
            }
        case let .string(value):
            hasher.combine(4)
            hasher.combine(value)
        case let .array(value):
            hasher.combine(5)
            hasher.combine(value)
        case let .object(value):
            hasher.combine(6)
            hasher.combine(value)
        }
    }
}

// MARK: - Codable

extension JSONValue: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .int(value):
            try container.encode(value)
        case let .double(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }
}

// MARK: - Literals

extension JSONValue: ExpressibleByNilLiteral, ExpressibleByBooleanLiteral, ExpressibleByIntegerLiteral,
    ExpressibleByFloatLiteral, ExpressibleByStringLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral
{
    public init(nilLiteral _: ()) {
        self = .null
    }

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

    public init(integerLiteral value: Int) {
        self = .int(value)
    }

    public init(floatLiteral value: Double) {
        self = .double(value)
    }

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }

    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements, uniquingKeysWith: { _, last in last }))
    }
}
