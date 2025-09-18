//
// Copyright © 2025 Alexander Romanov
// OversizeArchitecture.swift, created on 12.09.2025
//

@attached(extension, names: named(Action))
@attached(member, names: named(handleAction), named(state), named(input), named(output), named(init))
public macro ViewModel(module: Any.Type? = nil) = #externalMacro(module: "OversizeArchitectureMacros", type: "ViewModelMacro")

@attached(member, names: named(viewState), named(reducer), named(init))
public macro View(module: Any.Type) = #externalMacro(module: "OversizeArchitectureMacros", type: "ViewMacro")
