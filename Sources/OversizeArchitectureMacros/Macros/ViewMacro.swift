//
// Copyright © 2025 Alexander Romanov
// ViewMacro.swift, created on 18.09.2025
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ViewMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.as(StructDeclSyntax.self) != nil else {
            throw ViewMacroError.onlyApplicableToStruct
        }

        let moduleType = extractModuleType(from: node)

        var members: [DeclSyntax] = []

        if let module = moduleType {
            let properties = generateViewProperties(module: module)
            let initializer = generateViewInitializer(module: module)
            members.append(contentsOf: properties)
            members.append(DeclSyntax(initializer))
        }

        return members
    }
}

enum ViewMacroError: Error, CustomStringConvertible {
    case onlyApplicableToStruct

    var description: String {
        switch self {
        case .onlyApplicableToStruct:
            "@View can only be applied to structs"
        }
    }
}

private extension ViewMacro {
    static func extractModuleType(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for argument in arguments {
            if argument.label?.text == "module" {
                if let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
                   let baseType = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self) {
                    return baseType.baseName.text
                }
                if let declRef = argument.expression.as(DeclReferenceExprSyntax.self) {
                    return declRef.baseName.text
                }
            }
        }
        return nil
    }

    static func generateViewProperties(module: String) -> [DeclSyntax] {
        return [
            DeclSyntax(
                try! VariableDeclSyntax(
                    """
                    @Bindable var viewState: \(raw: module).ViewState
                    """
                )
            ),
            DeclSyntax(
                try! VariableDeclSyntax(
                    """
                    let reducer: Reducer<\(raw: module).ViewModel>
                    """
                )
            )
        ]
    }

    static func generateViewInitializer(module: String) -> InitializerDeclSyntax {
        return try! InitializerDeclSyntax(
            """
            @MainActor
            public init(viewState: \(raw: module).ViewState, reducer: Reducer<\(raw: module).ViewModel>) {
                self.viewState = viewState
                self.reducer = reducer
            }
            """
        )
    }
}