//
// Copyright © 2025 Alexander Romanov
// OversizeArchitecture.swift, created on 12.09.2025
//

@attached(extension, names: named(Action))
@attached(member, names: named(handleAction))
public macro ViewModel() = #externalMacro(module: "OversizeArchitectureMacros", type: "ViewModelMacro")

@attached(member, names: named(build))
public macro Screen(_ buildTypes: BuildType...) = #externalMacro(module: "OversizeArchitectureMacros", type: "ScreenMacro")

public enum BuildType {
    case `default`
    case id
}
