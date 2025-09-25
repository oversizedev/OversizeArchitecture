//
// Copyright © 2025 Alexander Romanov
// ModuleMacroTests.swift, created on 18.09.2025
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("Module Macro Tests")
struct ModuleMacroTests {
    let testMacros: [String: Macro.Type] = [
        "ModuleMacro": ModuleMacro.self,
    ]

    @Test("Module macro generates typealiases from name")
    func moduleMacroGeneratesTypealiasesFromName() {
        assertMacroExpansion(
            """
            @ModuleMacro
            public enum ProductEdit: ModuleProtocol {
            }
            """,
            expandedSource: """
            public enum ProductEdit: ModuleProtocol {
                public typealias Input = ProductEditInput
                public typealias Output = ProductEditOutput
                public typealias ViewState = ProductEditViewState
                public typealias ViewModel = ProductEditViewModel
                public typealias ViewScene = ProductEditView
            }
            """,
            macros: testMacros
        )
    }

    @Test("Module macro generates typealiases from explicit prefix")
    func moduleMacroGeneratesTypealiasesFromExplicitPrefix() {
        assertMacroExpansion(
            """
            @ModuleMacro(prefix: "CustomName")
            public enum SomeModule: ModuleProtocol {
            }
            """,
            expandedSource: """
            public enum SomeModule: ModuleProtocol {
                public typealias Input = CustomNameInput
                public typealias Output = CustomNameOutput
                public typealias ViewState = CustomNameViewState
                public typealias ViewModel = CustomNameViewModel
                public typealias ViewScene = CustomNameView
            }
            """,
            macros: testMacros
        )
    }

    @Test("Module macro works with ProductDetail")
    func moduleMacroWorksWithProductDetail() {
        assertMacroExpansion(
            """
            @ModuleMacro
            public enum ProductDetail: ModuleProtocol {
            }
            """,
            expandedSource: """
            public enum ProductDetail: ModuleProtocol {
                public typealias Input = ProductDetailInput
                public typealias Output = ProductDetailOutput
                public typealias ViewState = ProductDetailViewState
                public typealias ViewModel = ProductDetailViewModel
                public typealias ViewScene = ProductDetailView
            }
            """,
            macros: testMacros
        )
    }

    @Test("Module macro works with ProductList")
    func moduleMacroWorksWithProductList() {
        assertMacroExpansion(
            """
            @ModuleMacro
            public enum ProductList: ModuleProtocol {
            }
            """,
            expandedSource: """
            public enum ProductList: ModuleProtocol {
                public typealias Input = ProductListInput
                public typealias Output = ProductListOutput
                public typealias ViewState = ProductListViewState
                public typealias ViewModel = ProductListViewModel
                public typealias ViewScene = ProductListView
            }
            """,
            macros: testMacros
        )
    }

    @Test("Module macro only applies to enum")
    func moduleMacroOnlyAppliesToEnum() {
        assertMacroExpansion(
            """
            @ModuleMacro
            public struct ProductEdit: ModuleProtocol {
            }
            """,
            expandedSource: """
            public struct ProductEdit: ModuleProtocol {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Module can only be applied to enums", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }

    @Test("Module macro handles name without Module suffix")
    func moduleMacroHandlesNameWithoutModuleSuffix() {
        assertMacroExpansion(
            """
            @ModuleMacro
            public enum UserProfile: ModuleProtocol {
            }
            """,
            expandedSource: """
            public enum UserProfile: ModuleProtocol {
                public typealias Input = UserProfileInput
                public typealias Output = UserProfileOutput
                public typealias ViewState = UserProfileViewState
                public typealias ViewModel = UserProfileViewModel
                public typealias ViewScene = UserProfileView
            }
            """,
            macros: testMacros
        )
    }
}
