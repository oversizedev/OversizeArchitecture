//
// Copyright © 2026 Alexander Romanov
// ReducerTests.swift, created on 13.11.2026
//

@testable import OversizeArchitecture
import OversizeArchitectureTesting
import Testing

@MainActor
struct ReducerTests {
    @Test("Actions enter the ViewModel in the order they are sent")
    func actionsStartInSendOrder() async {
        let host = ModuleTestHost<ActionLog>()
        let indices = Array(0 ..< 200)

        let tasks = indices.map { index in
            host.reducer(.onRecord(index))
        }
        for task in tasks {
            await task.value
        }

        let receivedIndices = await host.viewModel.receivedIndices
        #expect(receivedIndices == indices)
    }

    @Test("A long action does not block the next one")
    func longActionDoesNotBlockNextAction() async {
        let gate = ActionLogGate()
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Log", gate: gate))

        let waitTask = host.reducer(.onWait)
        await host.send(.onRecord(1))

        #expect(host.state.entries == ["record-1"])

        await gate.open()
        await waitTask.value

        #expect(host.state.entries == ["record-1", "wait"])
    }

    @Test("Send waits for the action to finish")
    func sendWaitsForCompletion() async {
        let host = ModuleTestHost<ActionLog>()

        await host.reducer.send(.onRecord(1))

        #expect(host.state.entries == ["record-1"])
        #expect(host.reducer.pendingTaskCount == 0)
    }

    @Test("Cancelling the caller of send cancels the action")
    func cancellingSendCancelsAction() async {
        let host = ModuleTestHost<ActionLog>()

        let caller = Task {
            await host.reducer.send(.onSleep)
        }
        caller.cancel()
        await caller.value

        #expect(host.state.entries == ["sleep-cancelled"])
    }

    @Test("cancelAll cancels running actions")
    func cancelAllCancelsRunningActions() async {
        let host = ModuleTestHost<ActionLog>()

        let first = host.reducer(.onSleep)
        let second = host.reducer(.onSleep)
        host.reducer.cancelAll()
        await first.value
        await second.value

        #expect(host.state.entries == ["sleep-cancelled", "sleep-cancelled"])
        #expect(host.reducer.pendingTaskCount == 0)
    }

    @Test("Actions are not cancelled without an explicit request")
    func actionsKeepRunningWithoutCancellation() async {
        let gate = ActionLogGate()
        var host: ModuleTestHost<ActionLog>? = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Log", gate: gate))
        let state = host?.state
        let waitTask = host?.reducer(.onWait)

        host = nil
        await gate.open()
        await waitTask?.value

        #expect(state?.entries == ["wait"])
    }
}
