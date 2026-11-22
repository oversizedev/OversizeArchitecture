//
// Copyright © 2026 Alexander Romanov
// DebugServer.swift, created on 22.11.2026
//

import Foundation
import OversizeArchitecture
#if canImport(Network)
import Network
#endif

public enum DebugServerError: Error, Equatable, Sendable {
    case unavailable
    case alreadyStarted
    case cancelled
    case invalidPort(UInt16)
    case listenerFailed(String)
}

@MainActor
public final class DebugServer {
    public struct Configuration: Sendable {
        public var port: UInt16
        public var token: String?
        public var maximumMessageLength: Int

        public init(
            port: UInt16 = DebugServer.defaultPort,
            token: String? = nil,
            maximumMessageLength: Int = 1 << 20
        ) {
            self.port = port
            self.token = token
            self.maximumMessageLength = maximumMessageLength
        }
    }

    public nonisolated static let defaultPort: UInt16 = 47800

    public nonisolated static var isAvailable: Bool {
        #if DEBUG && canImport(Network) && !os(watchOS)
        true
        #else
        false
        #endif
    }

    public let registry: ModuleRegistry
    public let configuration: Configuration
    public private(set) var port: UInt16?

    private let appInfo: DebugAppInfo

    #if DEBUG && canImport(Network) && !os(watchOS)
    private let queue = DispatchQueue(label: "OversizeArchitectureDebug.DebugServer")
    private var listener: NWListener?
    private var connections: [ObjectIdentifier: (connection: NWConnection, task: Task<Void, Never>)] = [:]
    private var startContinuation: CheckedContinuation<UInt16, any Error>?
    #endif

    public init(
        registry: ModuleRegistry,
        configuration: Configuration = Configuration(),
        appInfo: DebugAppInfo = .current()
    ) {
        self.registry = registry
        self.configuration = configuration
        self.appInfo = appInfo
    }

    public var connectionCount: Int {
        #if DEBUG && canImport(Network) && !os(watchOS)
        connections.count
        #else
        0
        #endif
    }

    #if DEBUG && canImport(Network) && !os(watchOS)

    @discardableResult
    public func start() async throws -> UInt16 {
        guard listener == nil else {
            throw DebugServerError.alreadyStarted
        }

        let endpointPort: NWEndpoint.Port
        if configuration.port == 0 {
            endpointPort = .any
        } else if let port = NWEndpoint.Port(rawValue: configuration.port) {
            endpointPort = port
        } else {
            throw DebugServerError.invalidPort(configuration.port)
        }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: endpointPort)

        let listener: NWListener
        do {
            listener = try NWListener(using: parameters)
        } catch {
            throw DebugServerError.listenerFailed(String(describing: error))
        }

        listener.stateUpdateHandler = { [weak self, weak listener] state in
            Task { @MainActor in
                guard let listener else { return }
                self?.listenerStateChanged(state, of: listener)
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            Task { @MainActor in
                self?.accept(connection)
            }
        }
        self.listener = listener

        return try await withCheckedThrowingContinuation { continuation in
            startContinuation = continuation
            listener.start(queue: queue)
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        port = nil
        for entry in connections.values {
            entry.task.cancel()
            entry.connection.cancel()
        }
        connections.removeAll()
        finishStart(.failure(DebugServerError.cancelled))
    }

    private func listenerStateChanged(_ state: NWListener.State, of source: NWListener) {
        guard source === listener else { return }
        switch state {
        case .ready:
            let actualPort = listener?.port?.rawValue ?? configuration.port
            port = actualPort
            finishStart(.success(actualPort))
        case let .failed(error), let .waiting(error):
            finishStart(.failure(DebugServerError.listenerFailed(String(describing: error))))
            stop()
        case .cancelled:
            finishStart(.failure(DebugServerError.cancelled))
        default:
            break
        }
    }

    private func finishStart(_ result: Result<UInt16, any Error>) {
        guard let continuation = startContinuation else { return }
        startContinuation = nil
        continuation.resume(with: result)
    }

    private func accept(_ connection: NWConnection) {
        guard listener != nil else {
            connection.cancel()
            return
        }

        let key = ObjectIdentifier(connection)
        let handler = DebugRequestHandler(registry: registry, appInfo: appInfo, token: configuration.token)
        let maximumLength = configuration.maximumMessageLength
        let task = Task { [weak self] in
            await Self.serve(connection, handler: handler, maximumLength: maximumLength)
            self?.connections[key] = nil
        }
        connections[key] = (connection, task)
        connection.start(queue: queue)
    }

    private static func serve(_ connection: NWConnection, handler: DebugRequestHandler, maximumLength: Int) async {
        var framer = LineFramer(maximumLineLength: maximumLength)
        do {
            while !Task.isCancelled {
                guard let chunk = try await connection.receiveChunk() else { break }
                for line in try framer.append(chunk) {
                    if let response = await handler.handle(line) {
                        try await connection.sendLine(response)
                    }
                }
            }
        } catch LineFramer.FramingError.lineTooLong {
            let error = DebugRPCError.invalidRequest("Message exceeds \(maximumLength) bytes")
            if let response = try? DebugCoding.encodeLine(DebugResponse(id: nil, error: error)) {
                try? await connection.sendLine(response)
            }
        } catch {}
        connection.cancel()
    }

    #else

    @discardableResult
    public func start() async throws -> UInt16 {
        throw DebugServerError.unavailable
    }

    public func stop() {}

    #endif
}
