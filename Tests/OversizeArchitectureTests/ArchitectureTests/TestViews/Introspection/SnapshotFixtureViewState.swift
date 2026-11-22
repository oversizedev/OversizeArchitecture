//
// Copyright © 2026 Alexander Romanov
// SnapshotFixtureViewState.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture
import Observation

struct SnapshotFixtureItem: Hashable {
    let name: String
    let tags: [String]
}

enum SnapshotFixtureMode {
    case idle
    case loading(progress: Int)
    case failed(String, code: Int)
}

final class SnapshotFixtureNode {
    let name: String
    var parent: SnapshotFixtureNode?

    init(name: String) {
        self.name = name
    }
}

@Observable
final class SnapshotFixtureViewState: IntrospectableViewState {
    var title = "Fixture"
    var count = 3
    var ratio = 0.5
    var isEnabled = true
    var missing: Int?
    var present: Int? = 7
    var date = Date(timeIntervalSince1970: 0)
    var url = URL(string: "https://example.com/path")!
    var identifier = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    var price = Decimal(string: "19.99")!
    var items = [SnapshotFixtureItem(name: "first", tags: ["a", "b"])]
    var idleMode = SnapshotFixtureMode.idle
    var loadingMode = SnapshotFixtureMode.loading(progress: 40)
    var failedMode = SnapshotFixtureMode.failed("timeout", code: 504)
    var scores = ["alpha": 1, "beta": 2]
    var flags: Set<String> = ["zeta", "alpha", "mid"]
    var node = SnapshotFixtureNode(name: "root")
    @ObservationIgnored var _shadow = "underscored"
    @ObservationIgnored var shadow = "plain"
    let constant = "fixed"

    init(input _: Void?) {
        node.parent = node
    }
}
