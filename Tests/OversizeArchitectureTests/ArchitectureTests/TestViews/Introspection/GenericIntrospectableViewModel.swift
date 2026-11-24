//
// Copyright © 2026 Alexander Romanov
// GenericIntrospectableViewModel.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture

@ViewModel(introspectable: true)
actor GenericIntrospectableViewModel<Item: Codable & Sendable> {
    private(set) var received: [Item] = []

    func onReceive(_ item: Item) async {
        received.append(item)
    }
}
