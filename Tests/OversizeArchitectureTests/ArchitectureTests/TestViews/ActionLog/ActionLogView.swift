//
// Copyright © 2026 Alexander Romanov
// ActionLogView.swift, created on 13.11.2026
//

@testable import OversizeArchitecture
import SwiftUI

@View(module: ActionLog.self)
public struct ActionLogView: ViewProtocol {
    public var body: some View {
        List(viewState.entries, id: \.self) { entry in
            Text(entry)
        }
        .navigationTitle(viewState.title)
        .task { await reducer.send(.onRecord(0)) }
    }
}

#Preview("Action Log") {
    ActionLog.build(input: ActionLogInput(title: "Preview"))
}
