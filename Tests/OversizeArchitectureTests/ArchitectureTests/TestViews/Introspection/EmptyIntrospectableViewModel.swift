//
// Copyright © 2026 Alexander Romanov
// EmptyIntrospectableViewModel.swift, created on 22.11.2026
//

import Foundation
@testable import OversizeArchitecture

@ViewModel(introspectable: true)
actor EmptyIntrospectableViewModel {
    func load() async {}
}
