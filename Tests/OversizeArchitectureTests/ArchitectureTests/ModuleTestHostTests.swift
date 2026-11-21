//
// Copyright © 2026 Alexander Romanov
// ModuleTestHostTests.swift, created on 13.11.2026
//

@testable import OversizeArchitecture
import OversizeArchitectureTesting
import Testing

@MainActor
struct ModuleTestHostTests {
    @Test("Builds state from input")
    func buildsStateFromInput() {
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Custom"))

        #expect(host.state.title == "Custom")
        #expect(host.viewModel.state === host.state)
    }

    @Test("Builds state without input")
    func buildsStateWithoutInput() {
        let host = ModuleTestHost<ActionLog>()

        #expect(host.state.title == "Log")
        #expect(host.state.entries.isEmpty)
    }

    @Test("Sends several actions one after another")
    func sendsSeveralActionsSequentially() async {
        let host = ModuleTestHost<ActionLog>()

        await host.send(.onRecord(1), .onRecord(2), .onRecord(3))

        #expect(host.state.entries == ["record-1", "record-2", "record-3"])
    }

    @Test("Passes output to the ViewModel")
    func passesOutputToViewModel() async {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let output = ActionLogOutput(onRecord: Callback { index in
            continuation.yield(index)
        })
        let host = ModuleTestHost<ActionLog>(output: output)

        await host.send(.onRecord(7), .onRecord(8))
        continuation.finish()

        var received: [Int] = []
        for await index in stream {
            received.append(index)
        }
        #expect(received == [7, 8])
    }
}
