//
// Copyright © 2025 Alexander Romanov
// ScreenMacro.swift, created on 17.09.2025
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ScreenMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ScreenMacroError.onlyApplicableToStruct
        }
        
        let structName = structDecl.name.text
        let buildTypes = extractBuildTypes(from: node)
        
        var methods: [DeclSyntax] = []
        
        // Generate build methods based on the specified types
        if buildTypes.isEmpty || buildTypes.contains(.default) {
            methods.append(generateDefaultBuildMethod(structName: structName))
        }
        
        if buildTypes.contains(.id) {
            methods.append(generateIdBuildMethod(structName: structName))
        }
        
        return methods
    }
    
    private static func extractBuildTypes(from node: AttributeSyntax) -> Set<BuildType> {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return [.default] // Default behavior when no arguments
        }
        
        var types: Set<BuildType> = []
        
        for argument in arguments {
            if let memberAccess = argument.expression.as(MemberAccessExprSyntax.self) {
                let memberName = memberAccess.declName.baseName.text
                switch memberName {
                case "default":
                    types.insert(.default)
                case "id":
                    types.insert(.id)
                default:
                    break
                }
            }
        }
        
        return types.isEmpty ? [.default] : types
    }
    
    private static func replaceScreenWithViewState(_ name: String) -> String {
        if name.hasSuffix("Screen") {
            let index = name.index(name.endIndex, offsetBy: -6) // Remove "Screen"
            return String(name[..<index]) + "ViewState"
        }
        return name + "ViewState"
    }
    
    private static func replaceScreenWithViewModel(_ name: String) -> String {
        if name.hasSuffix("Screen") {
            let index = name.index(name.endIndex, offsetBy: -6) // Remove "Screen"
            return String(name[..<index]) + "ViewModel"
        }
        return name + "ViewModel"
    }
    
    private static func generateDefaultBuildMethod(structName: String) -> DeclSyntax {
        let viewStateName = replaceScreenWithViewState(structName)
        let viewModelName = replaceScreenWithViewModel(structName)
        
        return DeclSyntax(try! FunctionDeclSyntax(
            """
            @MainActor
            public static func build() -> some View {
                logNotice("Building \(raw: structName)")
                let viewState = \(raw: viewStateName)()
                let viewModel = \(raw: viewModelName)(state: viewState)
                let reducer = Reducer(viewModel: viewModel)
                return \(raw: structName)(viewState: viewState, reducer: reducer)
            }
            """
        ))
    }
    
    private static func generateIdBuildMethod(structName: String) -> DeclSyntax {
        let viewStateName = replaceScreenWithViewState(structName)
        let viewModelName = replaceScreenWithViewModel(structName)
        
        return DeclSyntax(try! FunctionDeclSyntax(
            """
            @MainActor
            public static func build(id: UUID) -> some View {
                logNotice("Building \(raw: structName) for ID: \\(id)")
                let viewState = \(raw: viewStateName)(id: id)
                let viewModel = \(raw: viewModelName)(state: viewState)
                let reducer = Reducer(viewModel: viewModel)
                return \(raw: structName)(viewState: viewState, reducer: reducer)
            }
            """
        ))
    }
}

enum BuildType: Hashable {
    case `default`
    case id
}

enum ScreenMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct
    
    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            "@Screen can only be applied to structs"
        }
    }
}
