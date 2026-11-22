//
// Copyright © 2026 Alexander Romanov
// DebugClient.swift, created on 22.11.2026
//

#if canImport(Network)
import Foundation
import Network
import OversizeArchitecture
import OversizeArchitectureDebug

public enum DebugClientError: Error, Equatable, Sendable, CustomStringConvertible {
    case invalidPort(UInt16)
    case connectionFailed(String)
    case connectionClosed
    case timedOut
    case invalidResponse

    public var description: String {
        switch self {
        case let .invalidPort(port):
            "Invalid port \(port)"
        case let .connectionFailed(reason):
            "Cannot connect to the app: \(reason)"
        case .connectionClosed:
            "The app closed the connection"
        case .timedOut:
            "The app did not answer in time"
        case .invalidResponse:
            "The app sent an invalid response"
        }
    }
}

public actor DebugClient: DebugTransport {
    public struct Configuration: Sendable {
        public var host: String
        public var port: UInt16
        public var token: String?
        public var timeout: Duration

        public init(
            host: String = "127.0.0.1",
            port: UInt16 = DebugServer.defaultPort,
            token: String? = nil,
            timeout: Duration = .seconds(30)
        ) {
            self.host = host
            self.port = port
            self.token = token
            self.timeout = timeout
        }
    }

    public nonisolated let configuration: Configuration
    public private(set) var appInfo: JSONValue?

    private let queue = DispatchQueue(label: "OversizeArchitectureDebug.DebugClient")
    private var connection: NWConnection?
    private var connectContinuation: CheckedContinuation<Void, any Error>?
    private var framer = LineFramer()
    private var pendingLines: [Data] = []
    private var nextIdentifier = 1
    private var isBusy = false
    private var activeRequest: UUID?
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    public func request(_ method: String, params: JSONValue? = nil) async throws -> JSONValue {
        await acquire()
        defer { release() }
        let requestIdentifier = UUID()
        activeRequest = requestIdentifier
        defer { activeRequest = nil }
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withDeadline {
                try await self.connectIfNeeded()
                return try await self.exchange(method, params: params)
            }
        } onCancel: {
            Task { await self.cancelRequest(requestIdentifier) }
        }
    }

    private func cancelRequest(_ identifier: UUID) {
        guard activeRequest == identifier else { return }
        reset()
    }

    public func close() {
        reset()
    }

    // MARK: - Serialization

    private func acquire() async {
        guard isBusy else {
            isBusy = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    private func release() {
        if waiters.isEmpty {
            isBusy = false
        } else {
            waiters.removeFirst().resume()
        }
    }

    // MARK: - Connection

    private func connectIfNeeded() async throws {
        guard connection == nil else { return }
        guard let port = NWEndpoint.Port(rawValue: configuration.port) else {
            throw DebugClientError.invalidPort(configuration.port)
        }

        let connection = NWConnection(host: NWEndpoint.Host(configuration.host), port: port, using: .tcp)
        self.connection = connection
        framer = LineFramer()
        pendingLines = []

        connection.stateUpdateHandler = { [weak self] state in
            Task { await self?.connectionStateChanged(state, of: connection) }
        }

        do {
            try await withCheckedThrowingContinuation { continuation in
                connectContinuation = continuation
                connection.start(queue: queue)
            }
            var params: [String: JSONValue] = [:]
            if let token = configuration.token {
                params["token"] = .string(token)
            }
            appInfo = try await exchange(DebugMethod.hello.rawValue, params: .object(params))
        } catch {
            reset()
            throw error
        }
    }

    private func connectionStateChanged(_ state: NWConnection.State, of source: NWConnection) {
        guard source === connection else { return }
        switch state {
        case .ready:
            finishConnect(nil)
        case let .waiting(error), let .failed(error):
            finishConnect(DebugClientError.connectionFailed(error.localizedDescription))
            reset()
        case .cancelled:
            finishConnect(DebugClientError.connectionClosed)
        default:
            break
        }
    }

    private func finishConnect(_ error: (any Error)?) {
        guard let continuation = connectContinuation else { return }
        connectContinuation = nil
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }

    private func reset() {
        finishConnect(DebugClientError.connectionClosed)
        connection?.stateUpdateHandler = nil
        connection?.cancel()
        connection = nil
        pendingLines = []
    }

    // MARK: - Exchange

    private func exchange(_ method: String, params: JSONValue?) async throws -> JSONValue {
        guard let connection else {
            throw DebugClientError.connectionClosed
        }

        let identifier = nextIdentifier
        nextIdentifier += 1
        let request = DebugRequest(id: .int(identifier), method: method, params: params)

        do {
            try await connection.sendLine(DebugCoding.encodeLine(request))
            while true {
                let line = try await nextLine(from: connection)
                guard let response = try? JSONDecoder().decode(DebugResponse.self, from: line) else {
                    throw DebugClientError.invalidResponse
                }
                guard response.id == .int(identifier) || response.id == nil else { continue }
                if let error = response.error {
                    throw error
                }
                return response.result ?? .null
            }
        } catch let error as DebugRPCError {
            throw error
        } catch let error as DebugClientError {
            reset()
            throw error
        } catch {
            reset()
            throw DebugClientError.connectionFailed(error.localizedDescription)
        }
    }

    private func nextLine(from connection: NWConnection) async throws -> Data {
        while pendingLines.isEmpty {
            guard let chunk = try await connection.receiveChunk() else {
                throw DebugClientError.connectionClosed
            }
            pendingLines.append(contentsOf: try framer.append(chunk))
        }
        return pendingLines.removeFirst()
    }

    private func withDeadline<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let timeout = configuration.timeout
        return try await withThrowingTaskGroup(of: Value?.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled else { return nil }
                await self.reset()
                throw DebugClientError.timedOut
            }
            defer { group.cancelAll() }
            while let result = try await group.next() {
                if let value = result {
                    return value
                }
            }
            throw DebugClientError.timedOut
        }
    }
}
#endif
