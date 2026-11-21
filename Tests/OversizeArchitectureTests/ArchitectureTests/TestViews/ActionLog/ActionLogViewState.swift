//
// Copyright © 2026 Alexander Romanov
// ActionLogViewState.swift, created on 13.11.2026
//

@testable import OversizeArchitecture
import SwiftUI

@Observable
public final class ActionLogViewState: ViewStateProtocol {
    public let title: String
    public var entries: [String] = []

    public init(input: ActionLog.Input?) {
        title = input?.title ?? "Log"
    }
}
