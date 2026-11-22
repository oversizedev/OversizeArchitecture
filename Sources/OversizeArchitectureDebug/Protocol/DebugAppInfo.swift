//
// Copyright © 2026 Alexander Romanov
// DebugAppInfo.swift, created on 22.11.2026
//

import Foundation

public struct DebugAppInfo: Codable, Sendable, Equatable {
    public static let protocolVersion = 1

    public let protocolVersion: Int
    public let bundleIdentifier: String
    public let processName: String
    public let processIdentifier: Int
    public let sessionIdentifier: UUID

    public init(
        bundleIdentifier: String,
        processName: String,
        processIdentifier: Int,
        sessionIdentifier: UUID = UUID()
    ) {
        protocolVersion = Self.protocolVersion
        self.bundleIdentifier = bundleIdentifier
        self.processName = processName
        self.processIdentifier = processIdentifier
        self.sessionIdentifier = sessionIdentifier
    }

    public static func current() -> DebugAppInfo {
        let processInfo = ProcessInfo.processInfo
        return DebugAppInfo(
            bundleIdentifier: Bundle.main.bundleIdentifier ?? processInfo.processName,
            processName: processInfo.processName,
            processIdentifier: Int(processInfo.processIdentifier)
        )
    }
}
