//
// Copyright © 2025 Alexander Romanov
// OversizeArchitecture.swift, created on 12.09.2025
//

@attached(extension, conformances: Sendable, names: named(Action))
@attached(member, names: named(handleAction))
public macro ViewModel() = #externalMacro(module: "OversizeArchitectureMacros", type: "ViewModelMacro")
