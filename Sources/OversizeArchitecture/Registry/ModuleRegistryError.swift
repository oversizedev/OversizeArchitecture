//
// Copyright © 2026 Alexander Romanov
// ModuleRegistryError.swift, created on 22.11.2026
//

import Foundation

public enum ModuleRegistryError: Error, Equatable, Sendable {
    case moduleNotFound(UUID)
    case moduleUnavailable(UUID)
    case stateNotIntrospectable(UUID)
    case actionsNotIntrospectable(UUID)
}
