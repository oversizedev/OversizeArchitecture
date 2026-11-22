//
// Copyright © 2026 Alexander Romanov
// StateReflector.swift, created on 22.11.2026
//

import Foundation

struct StateReflector {
    static let cycleMarker: JSONValue = "<cycle>"
    static let truncatedMarker: JSONValue = "<truncated>"

    let maxDepth: Int

    init(maxDepth: Int = 16) {
        self.maxDepth = maxDepth
    }

    func reflect(_ subject: Any) -> JSONValue {
        value(of: subject, depth: 0, visited: [])
    }

    private func value(of subject: Any, depth: Int, visited: Set<ObjectIdentifier>) -> JSONValue {
        let mirror = Mirror(reflecting: subject)

        if mirror.displayStyle == .optional {
            guard let wrapped = mirror.children.first?.value else { return .null }
            return value(of: wrapped, depth: depth, visited: visited)
        }

        if let scalar = scalar(of: subject) {
            return scalar
        }

        guard depth < maxDepth else {
            return Self.truncatedMarker
        }

        let nextDepth = depth + 1

        switch mirror.displayStyle {
        case .collection:
            return .array(mirror.children.map { value(of: $0.value, depth: nextDepth, visited: visited) })

        case .set:
            let elements = mirror.children
                .map(\.value)
                .sorted { String(describing: $0) < String(describing: $1) }
            return .array(elements.map { value(of: $0, depth: nextDepth, visited: visited) })

        case .dictionary:
            var object: [String: JSONValue] = [:]
            for entry in mirror.children {
                let pair = Array(Mirror(reflecting: entry.value).children)
                guard pair.count == 2 else { continue }
                let key = pair[0].value as? String ?? String(describing: pair[0].value)
                object[key] = value(of: pair[1].value, depth: nextDepth, visited: visited)
            }
            return .object(object)

        case .tuple:
            let children = Array(mirror.children)
            let isPositional = children.allSatisfy { $0.label?.hasPrefix(".") ?? true }
            if isPositional {
                return .array(children.map { value(of: $0.value, depth: nextDepth, visited: visited) })
            }
            var object: [String: JSONValue] = [:]
            for (index, child) in children.enumerated() {
                let label = child.label.flatMap { $0.hasPrefix(".") ? nil : $0 } ?? "_\(index)"
                object[label] = value(of: child.value, depth: nextDepth, visited: visited)
            }
            return .object(object)

        case .enum:
            guard let payload = mirror.children.first, let caseName = payload.label else {
                return .string(String(describing: subject))
            }
            return .object([caseName: value(of: payload.value, depth: nextDepth, visited: visited)])

        case .class:
            let identifier = ObjectIdentifier(subject as AnyObject)
            guard !visited.contains(identifier) else {
                return Self.cycleMarker
            }
            var children: [Mirror.Child] = []
            var current: Mirror? = mirror
            while let level = current {
                children.append(contentsOf: level.children)
                current = level.superclassMirror
            }
            return .object(fields(of: children, depth: nextDepth, visited: visited.union([identifier])))

        case .struct:
            return .object(fields(of: Array(mirror.children), depth: nextDepth, visited: visited))

        default:
            return .string(String(describing: subject))
        }
    }

    private func fields(of children: [Mirror.Child], depth: Int, visited: Set<ObjectIdentifier>) -> [String: JSONValue] {
        let labels = Set(children.compactMap(\.label))
        var object: [String: JSONValue] = [:]

        for (index, child) in children.enumerated() {
            let label = child.label ?? String(index)
            guard !label.hasPrefix("_$") else { continue }
            object[fieldName(for: label, siblings: labels)] = value(of: child.value, depth: depth, visited: visited)
        }

        return object
    }

    private func fieldName(for label: String, siblings: Set<String>) -> String {
        guard label.hasPrefix("_"), label.count > 1 else { return label }
        let stripped = String(label.dropFirst())
        return siblings.contains(stripped) ? label : stripped
    }

    private func scalar(of subject: Any) -> JSONValue? {
        if type(of: subject) is NSNumber.Type, let number = subject as? NSNumber {
            return numberScalar(number)
        }

        return switch subject {
        case let value as String:
            .string(value)
        case let value as Bool:
            .bool(value)
        case let value as Int:
            .int(value)
        case let value as Int8:
            integer(value)
        case let value as Int16:
            integer(value)
        case let value as Int32:
            integer(value)
        case let value as Int64:
            integer(value)
        case let value as UInt:
            integer(value)
        case let value as UInt8:
            integer(value)
        case let value as UInt16:
            integer(value)
        case let value as UInt32:
            integer(value)
        case let value as UInt64:
            integer(value)
        case let value as Double:
            .double(value)
        case let value as Float:
            .double(Double(value))
        case let value as Decimal:
            .string(value.description)
        case let value as Date:
            .string(value.formatted(.iso8601))
        case let value as URL:
            .string(value.absoluteString)
        case let value as UUID:
            .string(value.uuidString)
        default:
            nil
        }
    }

    private func integer(_ value: some BinaryInteger) -> JSONValue {
        if let exact = Int(exactly: value) {
            return .int(exact)
        }
        return .string(String(value))
    }

    private func numberScalar(_ number: NSNumber) -> JSONValue {
        if CFGetTypeID(number) == CFBooleanGetTypeID() {
            return .bool(number.boolValue)
        }
        if CFNumberIsFloatType(number) {
            return .double(number.doubleValue)
        }
        if String(cString: number.objCType) == "Q" {
            return integer(number.uint64Value)
        }
        return integer(number.int64Value)
    }
}
