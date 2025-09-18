//
// Copyright © 2025 Alexander Romanov
// ModuleMacro.swift, created on 18.09.2025
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ModuleMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.as(EnumDeclSyntax.self) != nil else {
            throw ModuleMacroError.onlyApplicableToEnum
        }

        let prefix = extractPrefix(from: node) ?? extractPrefixFromName(declaration: declaration)

        let members = generateModuleTypealiases(prefix: prefix)
        return members
    }
}

enum ModuleMacroError: Error, CustomStringConvertible {
    case onlyApplicableToEnum

    var description: String {
        switch self {
        case .onlyApplicableToEnum:
            "@Module can only be applied to enums"
        }
    }
}

private extension ModuleMacro {
    static func extractPrefix(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for argument in arguments {
            if argument.label?.text == "prefix" {
                if let stringLiteral = argument.expression.as(StringLiteralExprSyntax.self) {
                    return stringLiteral.segments.first?.as(StringSegmentSyntax.self)?.content.text
                }
            }
        }
        return nil
    }

    static func extractPrefixFromName(declaration: some DeclGroupSyntax) -> String {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            return "Unknown"
        }

        let fullName = enumDecl.name.text
        // Remove "Module" suffix if present
        if fullName.hasSuffix("Module") {
            return String(fullName.dropLast(6))
        }
        return fullName
    }

    static func generateModuleTypealiases(prefix: String) -> [DeclSyntax] {
        return [
            DeclSyntax(
                try! TypeAliasDeclSyntax(
                    """
                    public typealias Input = \(raw: prefix)Input
                    """
                )
            ),
            DeclSyntax(
                try! TypeAliasDeclSyntax(
                    """
                    public typealias Output = \(raw: prefix)Output
                    """
                )
            ),
            DeclSyntax(
                try! TypeAliasDeclSyntax(
                    """
                    public typealias ViewState = \(raw: prefix)ViewState
                    """
                )
            ),
            DeclSyntax(
                try! TypeAliasDeclSyntax(
                    """
                    public typealias ViewModel = \(raw: prefix)ViewModel
                    """
                )
            ),
            DeclSyntax(
                try! TypeAliasDeclSyntax(
                    """
                    public typealias ViewScene = \(raw: prefix)View
                    """
                )
            )
        ]
    }
}