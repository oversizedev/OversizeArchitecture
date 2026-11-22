//
// Copyright © 2026 Alexander Romanov
// ModuleDebugServerModifier.swift, created on 22.11.2026
//

import OSLog
import OversizeArchitecture
import SwiftUI

public extension View {
    func moduleDebugServer(
        _ configuration: DebugServer.Configuration = DebugServer.Configuration(),
        isEnabled: Bool = true
    ) -> some View {
        modifier(ModuleDebugServerModifier(configuration: configuration, isEnabled: isEnabled))
    }
}

private struct ModuleDebugServerModifier: ViewModifier {
    let configuration: DebugServer.Configuration
    let isEnabled: Bool

    #if DEBUG
    @State private var registry = ModuleRegistry()

    func body(content: Content) -> some View {
        if isEnabled, DebugServer.isAvailable {
            content
                .moduleRegistry(registry)
                .task {
                    let server = DebugServer(registry: registry, configuration: configuration)
                    let logger = Logger(subsystem: "OversizeArchitecture", category: "DebugServer")
                    do {
                        let port = try await server.start()
                        logger.notice("Module debug server listening on 127.0.0.1:\(port, privacy: .public)")
                        await Self.waitForCancellation()
                    } catch {
                        logger.error("Module debug server failed: \(String(describing: error), privacy: .public)")
                    }
                    server.stop()
                }
        } else {
            content
        }
    }

    private static func waitForCancellation() async {
        let (stream, continuation) = AsyncStream<Never>.makeStream()
        await withTaskCancellationHandler {
            for await _ in stream {}
        } onCancel: {
            continuation.finish()
        }
    }
    #else
    func body(content: Content) -> some View {
        content
    }
    #endif
}
