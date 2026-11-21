//
// Copyright © 2026 Alexander Romanov
// ActionLog.swift, created on 13.11.2026
//

import Foundation
@testable import OversizeArchitecture

public struct ActionLogInput: Sendable {
    public let title: String
    public let gate: ActionLogGate

    public init(title: String, gate: ActionLogGate = ActionLogGate()) {
        self.title = title
        self.gate = gate
    }
}

public struct ActionLogOutput: Sendable {
    public let onRecord: Callback<Int>

    public init(onRecord: Callback<Int>) {
        self.onRecord = onRecord
    }
}

public actor ActionLogGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    public init() {}

    public func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    public func open() {
        isOpen = true
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
}

@Module
public enum ActionLog: ModuleProtocol {}
