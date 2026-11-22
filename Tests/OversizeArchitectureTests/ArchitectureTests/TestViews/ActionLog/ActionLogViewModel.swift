//
// Copyright © 2026 Alexander Romanov
// ActionLogViewModel.swift, created on 13.11.2026
//

@testable import OversizeArchitecture
import SwiftUI

@ViewModel(module: ActionLog.self, introspectable: true)
public actor ActionLogViewModel: ViewModelProtocol {
    private(set) var receivedIndices: [Int] = []

    func onRecord(_ index: Int) async {
        receivedIndices.append(index)
        await append("record-\(index)")
        output?.onRecord(index)
    }

    func onWait() async {
        await input?.gate.wait()
        await append("wait")
    }

    func onSleep() async {
        do {
            try await Task.sleep(for: .seconds(30))
            await append("sleep-finished")
        } catch {
            await append("sleep-cancelled")
        }
    }

    private func append(_ entry: String) async {
        await state.update { state in
            state.entries.append(entry)
        }
    }
}
