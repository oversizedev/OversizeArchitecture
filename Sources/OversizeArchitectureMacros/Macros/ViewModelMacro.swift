//
// Copyright © 2025 Alexander Romanov
// ViewModelMacro.swift, created on 12.09.2025
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct ViewModelMacro: ExtensionMacro, MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let declGroup = declaration.as(ClassDeclSyntax.self) as (any DeclGroupSyntax)? ??
            declaration.as(ActorDeclSyntax.self) as (any DeclGroupSyntax)?
        else {
            throw ViewModelMacroError.onlyApplicableToClassOrActor
        }

        let onMethods = extractOnMethods(from: declGroup)
        let actionCases = generateActionCases(from: onMethods)

        let actionEnum = EnumDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.public))
            },
            name: "Action",
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(type: IdentifierTypeSyntax(name: "Sendable"))
            }
        ) {
            for actionCase in actionCases {
                MemberBlockItemSyntax(decl: actionCase)
            }
        }

        let extensionDecl = ExtensionDeclSyntax(
            extendedType: type,
            memberBlock: MemberBlockSyntax {
                MemberBlockItemSyntax(decl: actionEnum)
            }
        )

        return [extensionDecl]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declGroup = declaration.as(ClassDeclSyntax.self) as (any DeclGroupSyntax)? ??
            declaration.as(ActorDeclSyntax.self) as (any DeclGroupSyntax)?
        else {
            throw ViewModelMacroError.onlyApplicableToClassOrActor
        }

        let moduleType = extractModuleType(from: node)
        let onMethods = extractOnMethods(from: declGroup)
        let isTypeGloballyIsolated = declarationHasExplicitGlobalActorAttribute(declGroup)
        let handleActionMethod = generateHandleActionMethod(from: onMethods, isTypeGloballyIsolated: isTypeGloballyIsolated)

        var members: [DeclSyntax] = []

        if let module = moduleType {
            let properties = generateModuleProperties(module: module)
            let initializer = generateInitializer(module: module)
            members.append(contentsOf: properties)
            members.append(DeclSyntax(initializer))
        }

        members.append(DeclSyntax(handleActionMethod))

        return members
    }

    private static func extractOnMethods(from declaration: some DeclGroupSyntax) -> [FunctionDeclSyntax] {
        declaration.memberBlock.members.compactMap { member in
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  function.name.text.hasPrefix("on"),
                  !function.modifiers.contains(where: { $0.name.tokenKind == .keyword(.private) })
            else {
                return nil
            }
            return function
        }
    }

    private static func generateActionCases(from methods: [FunctionDeclSyntax]) -> [EnumCaseDeclSyntax] {
        methods.compactMap { method in
            let methodName = method.name.text
            let caseName = methodName

            let caseElement: EnumCaseElementSyntax

            if method.signature.parameterClause.parameters.isEmpty {
                caseElement = EnumCaseElementSyntax(name: TokenSyntax.identifier(caseName))
            } else {
                let parameters = method.signature.parameterClause.parameters

                var enumParameters: [EnumCaseParameterSyntax] = []

                for (index, param) in parameters.enumerated() {
                    let labelText = param.firstName.text

                    let enumParam = if labelText == "_" {
                        EnumCaseParameterSyntax(type: param.type)
                    } else {
                        EnumCaseParameterSyntax(
                            firstName: TokenSyntax.identifier(labelText),
                            colon: .colonToken(),
                            type: param.type
                        )
                    }

                    if index < parameters.count - 1 {
                        enumParameters.append(enumParam.with(\.trailingComma, .commaToken()))
                    } else {
                        enumParameters.append(enumParam)
                    }
                }

                caseElement = EnumCaseElementSyntax(
                    name: TokenSyntax.identifier(caseName),
                    parameterClause: EnumCaseParameterClauseSyntax(
                        parameters: EnumCaseParameterListSyntax(enumParameters)
                    )
                )
            }

            return EnumCaseDeclSyntax(
                elements: EnumCaseElementListSyntax {
                    caseElement
                }
            )
        }
    }

    private static func methodIsAsync(_ method: FunctionDeclSyntax) -> Bool {
        method.signature.effectSpecifiers?.asyncSpecifier != nil
    }

    private static func hasExplicitGlobalActorAttribute(_ attributes: AttributeListSyntax) -> Bool {
        attributes.contains {
            guard case let .attribute(attr) = $0 else { return false }
            let lastComponent: String? = if let ident = attr.attributeName.as(IdentifierTypeSyntax.self) {
                ident.name.text
            } else if let member = attr.attributeName.as(MemberTypeSyntax.self) {
                member.name.text
            } else {
                nil
            }
            guard let lastComponent else { return false }
            return lastComponent.hasSuffix("Actor") && lastComponent != "reasync"
        }
    }

    /// A method explicitly isolated to a global actor (e.g. `@MainActor`, or a qualified
    /// custom global actor such as `@Namespace.UIActor`) needs an actor hop from the
    /// generated, non-isolated `handleAction`, so `await` must be kept even though the
    /// method itself is not `async`.
    private static func methodHasExplicitGlobalActorAttribute(_ method: FunctionDeclSyntax) -> Bool {
        hasExplicitGlobalActorAttribute(method.attributes)
    }

    /// Mirrors `methodHasExplicitGlobalActorAttribute` for isolation declared on the
    /// enclosing class/actor itself, which applies to every member without repeating
    /// the attribute on each method.
    ///
    /// This can't catch isolation inferred purely from witnessing a global-actor-isolated
    /// protocol requirement (no attribute appears anywhere in source in that case) — that
    /// requires type-checking information a syntax-only macro doesn't have. Callers relying
    /// on that inference should annotate the method explicitly to keep `handleAction` correct.
    private static func declarationHasExplicitGlobalActorAttribute(_ declaration: some DeclGroupSyntax) -> Bool {
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            return hasExplicitGlobalActorAttribute(classDecl.attributes)
        }
        if let actorDecl = declaration.as(ActorDeclSyntax.self) {
            return hasExplicitGlobalActorAttribute(actorDecl.attributes)
        }
        return false
    }

    private static func generateHandleActionMethod(
        from methods: [FunctionDeclSyntax],
        isTypeGloballyIsolated: Bool
    ) -> FunctionDeclSyntax {
        if methods.isEmpty {
            return try! FunctionDeclSyntax(
                """
                public func handleAction(_ action: Action) async {
                }
                """
            )
        }

        var caseStatements: [String] = []

        for method in methods {
            let methodName = method.name.text
            let caseName = methodName
            let needsAwait = methodIsAsync(method) || isTypeGloballyIsolated || methodHasExplicitGlobalActorAttribute(method)
            let callPrefix = needsAwait ? "await " : ""

            if method.signature.parameterClause.parameters.isEmpty {
                caseStatements.append("case .\(caseName):")
                caseStatements.append("    \(callPrefix)\(methodName)()")
            } else {
                let parameters = method.signature.parameterClause.parameters

                var caseParams: [String] = []
                var callArgs: [String] = []

                for param in parameters {
                    let firstName = param.firstName.text
                    if firstName == "_" {
                        let paramName = param.secondName?.text ?? "value"
                        caseParams.append(paramName)
                        callArgs.append(paramName)
                    } else {
                        caseParams.append(firstName)
                        callArgs.append("\(firstName): \(firstName)")
                    }
                }

                let casePattern = caseParams.joined(separator: ", ")
                let callPattern = callArgs.joined(separator: ", ")

                caseStatements.append("case let .\(caseName)(\(casePattern)):")
                caseStatements.append("    \(callPrefix)\(methodName)(\(callPattern))")
            }
        }

        let switchBody = caseStatements.joined(separator: "\n    ")

        return try! FunctionDeclSyntax(
            """
            public func handleAction(_ action: Action) async {
                switch action {
                \(raw: switchBody)
                }
            }
            """
        )
    }
}

enum ViewModelMacroError: Error, CustomStringConvertible {
    case onlyApplicableToClassOrActor

    var description: String {
        switch self {
        case .onlyApplicableToClassOrActor:
            "@ViewModelMacro can only be applied to classes or actors"
        }
    }
}

extension String {
    func lowercasingFirst() -> String {
        guard !isEmpty else { return self }
        return prefix(1).lowercased() + dropFirst()
    }
}

private extension ViewModelMacro {
    static func extractModuleType(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else {
            return nil
        }

        for argument in arguments {
            if argument.label?.text == "module" {
                if let memberAccessExpr = argument.expression.as(MemberAccessExprSyntax.self),
                   let baseType = memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)
                {
                    return baseType.baseName.text
                }
                if let declRef = argument.expression.as(DeclReferenceExprSyntax.self) {
                    return declRef.baseName.text
                }
            }
        }
        return nil
    }

    static func generateModuleProperties(module: String) -> [DeclSyntax] {
        [
            DeclSyntax(
                try! VariableDeclSyntax(
                    """
                    @MainActor
                    public var state: \(raw: module).ViewState
                    """
                )
            ),
            DeclSyntax(
                try! VariableDeclSyntax(
                    """
                    private let input: \(raw: module).Input?
                    """
                )
            ),
            DeclSyntax(
                try! VariableDeclSyntax(
                    """
                    private let output: \(raw: module).Output?
                    """
                )
            )
        ]
    }

    static func generateInitializer(module: String) -> InitializerDeclSyntax {
        try! InitializerDeclSyntax(
            """
            @MainActor
            public init(state: \(raw: module).ViewState, input: \(raw: module).Input?, output: \(raw: module).Output?) {
                self.state = state
                self.input = input
                self.output = output
            }
            """
        )
    }
}
