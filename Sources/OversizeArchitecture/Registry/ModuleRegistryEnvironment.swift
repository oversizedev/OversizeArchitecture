//
// Copyright © 2026 Alexander Romanov
// ModuleRegistryEnvironment.swift, created on 22.11.2026
//

import SwiftUI

public extension EnvironmentValues {
    @Entry var moduleRegistry: ModuleRegistry?
}

public extension View {
    func moduleRegistry(_ registry: ModuleRegistry?) -> some View {
        environment(\.moduleRegistry, registry)
    }
}
