//
// Copyright © 2026 Alexander Romanov
// ActionDescriptor.swift, created on 22.11.2026
//

public struct ActionDescriptor: Sendable, Codable, Hashable {
    public struct Parameter: Sendable, Codable, Hashable {
        public let label: String?
        public let codingKey: String
        public let type: String

        public init(label: String?, codingKey: String, type: String) {
            self.label = label
            self.codingKey = codingKey
            self.type = type
        }
    }

    public let name: String
    public let parameters: [Parameter]

    public init(name: String, parameters: [Parameter] = []) {
        self.name = name
        self.parameters = parameters
    }
}
