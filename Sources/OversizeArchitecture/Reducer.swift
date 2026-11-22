//
// Copyright © 2025 Alexander Romanov
// Reducer.swift, created on 04.07.2025
//

import Foundation

@MainActor
public final class Reducer<ViewModel: ViewModelProtocol> {
    private let viewModel: ViewModel
    private var tasks: [UUID: Task<Void, Never>] = [:]

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    @discardableResult
    public func callAsFunction(_ action: ViewModel.Action) -> Task<Void, Never> {
        let identifier = UUID()
        let viewModel = viewModel
        let task = Task { [weak self] in
            await viewModel.handleAction(action)
            self?.tasks[identifier] = nil
        }
        tasks[identifier] = task
        return task
    }

    public func send(_ action: ViewModel.Action) async {
        let task = callAsFunction(action)
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    public func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }

    var pendingTaskCount: Int {
        tasks.count
    }
}
