//
// Copyright © 2026 Alexander Romanov
// IntrospectableAction.swift, created on 22.11.2026
//

public protocol IntrospectableAction: Codable, Sendable {
    static var descriptors: [ActionDescriptor] { get }
}
