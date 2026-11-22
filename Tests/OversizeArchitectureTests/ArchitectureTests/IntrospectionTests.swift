//
// Copyright © 2026 Alexander Romanov
// IntrospectionTests.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
import OversizeArchitectureTesting
import Testing

@MainActor
struct IntrospectionTests {
    @Test("Generated descriptors list every action")
    func generatedDescriptorsListEveryAction() {
        #expect(ActionLog.ViewModel.Action.descriptors == [
            ActionDescriptor(name: "onRecord", parameters: [
                ActionDescriptor.Parameter(label: nil, codingKey: "_0", type: "Int")
            ]),
            ActionDescriptor(name: "onWait"),
            ActionDescriptor(name: "onSleep")
        ])
    }

    @Test("Empty introspectable ViewModel has no descriptors and rejects decoding")
    func emptyIntrospectableViewModel() {
        #expect(EmptyIntrospectableViewModel.Action.descriptors.isEmpty)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(EmptyIntrospectableViewModel.Action.self, from: Data("{}".utf8))
        }
    }

    @Test("Generic ViewModel generates descriptors and decodes actions")
    func genericViewModelGeneratesDescriptors() throws {
        #expect(GenericIntrospectableViewModel<String>.Action.descriptors == [
            ActionDescriptor(name: "onReceive", parameters: [
                ActionDescriptor.Parameter(label: nil, codingKey: "_0", type: "Item")
            ])
        ])

        let decoded = try JSONDecoder().decode(
            GenericIntrospectableViewModel<String>.Action.self,
            from: Data(#"{"onReceive":{"_0":"item"}}"#.utf8)
        )
        guard case let .onReceive(item) = decoded else {
            Issue.record("Unexpected action \(decoded)")
            return
        }
        #expect(item == "item")
    }

    @Test("Actions round-trip through JSON")
    func actionsRoundTripThroughJSON() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let encoded = try encoder.encode(ActionLog.ViewModel.Action.onRecord(5))
        #expect(String(decoding: encoded, as: UTF8.self) == #"{"onRecord":{"_0":5}}"#)

        let decoded = try JSONDecoder().decode(ActionLog.ViewModel.Action.self, from: encoded)
        guard case let .onRecord(index) = decoded else {
            Issue.record("Unexpected action \(decoded)")
            return
        }
        #expect(index == 5)
    }

    @Test("Action from JSON updates state visible in the snapshot")
    func actionFromJSONUpdatesSnapshot() async throws {
        let (stream, continuation) = AsyncStream<Int>.makeStream()
        let output = ActionLogOutput(onRecord: Callback { index in
            continuation.yield(index)
        })
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Agent"), output: output)

        try await host.send(json: #"{"onRecord":{"_0":5}}"#)
        continuation.finish()

        #expect(host.snapshot() == ["title": "Agent", "entries": ["record-5"]])
        var received: [Int] = []
        for await index in stream {
            received.append(index)
        }
        #expect(received == [5])
    }

    @Test("JSON actions enter the ViewModel in the order they are sent")
    func jsonActionsKeepEntryOrder() async throws {
        let host = ModuleTestHost<ActionLog>()

        try await host.send(json: #"{"onRecord":{"_0":1}}"#, #"{"onRecord":{"_0":2}}"#, #"{"onRecord":{"_0":3}}"#)

        #expect(await host.viewModel.receivedIndices == [1, 2, 3])
    }

    @Test("Reducer sends an action decoded from JSON data")
    func reducerSendsActionFromData() async throws {
        let host = ModuleTestHost<ActionLog>()

        try await host.reducer.send(json: Data(#"{"onRecord":{"_0":9}}"#.utf8))

        #expect(host.state.entries == ["record-9"])
    }

    @Test("Invalid JSON throws and dispatches nothing")
    func invalidJSONThrows() async {
        let host = ModuleTestHost<ActionLog>()

        await #expect(throws: DecodingError.self) {
            try await host.send(json: #"{"onUnknown":{}}"#)
        }
        await #expect(throws: DecodingError.self) {
            try await host.send(json: #"{"onRecord":{"_0":"five"}}"#)
        }

        #expect(await host.viewModel.receivedIndices.isEmpty)
        #expect(host.state.entries.isEmpty)
        #expect(host.reducer.pendingTaskCount == 0)
    }

    @Test("Snapshot JSON has sorted keys")
    func snapshotJSONHasSortedKeys() async throws {
        let host = ModuleTestHost<ActionLog>(input: ActionLogInput(title: "Sorted"))
        await host.send(.onRecord(1), .onRecord(2))

        let json = try String(decoding: host.state.snapshotJSON(), as: UTF8.self)

        #expect(json == #"{"entries":["record-1","record-2"],"title":"Sorted"}"#)
    }

    @Test("JSONValue encodes and decodes plain JSON")
    func jsonValueRoundTrip() throws {
        let value: JSONValue = ["flag": true, "count": 2, "ratio": 1.5, "name": "x", "none": nil, "list": [1, "two"]]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(value)

        #expect(String(decoding: data, as: UTF8.self) == #"{"count":2,"flag":true,"list":[1,"two"],"name":"x","none":null,"ratio":1.5}"#)
        #expect(try JSONDecoder().decode(JSONValue.self, from: data) == value)
    }
}

@MainActor
struct StateReflectorTests {
    @Test("Reflects an Observable ViewState into JSON values")
    func reflectsObservableViewState() {
        let snapshot = SnapshotFixtureViewState(input: nil).snapshot()

        #expect(snapshot == [
            "title": "Fixture",
            "count": 3,
            "ratio": 0.5,
            "isEnabled": true,
            "missing": nil,
            "present": 7,
            "date": "1970-01-01T00:00:00Z",
            "url": "https://example.com/path",
            "identifier": "00000000-0000-0000-0000-000000000001",
            "price": "19.99",
            "items": [["name": "first", "tags": ["a", "b"]]],
            "idleMode": "idle",
            "loadingMode": ["loading": ["progress": 40]],
            "failedMode": ["failed": ["_0": "timeout", "code": 504]],
            "scores": ["alpha": 1, "beta": 2],
            "flags": ["alpha", "mid", "zeta"],
            "node": ["name": "root", "parent": "<cycle>"],
            "_shadow": "underscored",
            "shadow": "plain",
            "constant": "fixed"
        ])
    }

    @Test("Keeps numeric types stable")
    func keepsNumericTypesStable() {
        struct Numbers {
            let zero = NSNumber(value: 0)
            let one = NSNumber(value: 1)
            let fraction = NSNumber(value: 1.5)
            let flag = NSNumber(value: true)
            let large = Int64(3_000_000_000)
            let small = Int8(-3)
            let unsigned = UInt64.max
            let unsignedNumber = NSNumber(value: UInt64.max)
            let optionalNumber: NSNumber? = NSNumber(value: 1)
        }

        #expect(StateReflector().reflect(Numbers()) == [
            "zero": 0,
            "one": 1,
            "fraction": 1.5,
            "flag": true,
            "large": 3_000_000_000,
            "small": -3,
            "unsigned": "18446744073709551615",
            "unsignedNumber": "18446744073709551615",
            "optionalNumber": 1
        ])
    }

    @Test("Snapshot survives a JSON round-trip")
    func snapshotSurvivesJSONRoundTrip() throws {
        struct Ratios {
            let whole = 1.0
            let half = 0.5
        }
        let snapshot = StateReflector().reflect(Ratios())
        let data = try JSONEncoder().encode(snapshot)

        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded == snapshot)
        #expect(Set([decoded, snapshot]).count == 1)
        #expect(JSONValue.int(1) != JSONValue.bool(true))
    }

    @Test("Stops at the depth limit")
    func stopsAtDepthLimit() {
        let reflected = StateReflector(maxDepth: 1).reflect(SnapshotFixtureItem(name: "deep", tags: ["x"]))

        #expect(reflected == ["name": "deep", "tags": "<truncated>"])
    }
}
