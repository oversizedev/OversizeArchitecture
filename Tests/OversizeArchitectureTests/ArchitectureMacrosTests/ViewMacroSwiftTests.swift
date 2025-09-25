//
// Copyright © 2025 Alexander Romanov
// ViewMacroSwiftTests.swift, created on 18.09.2025
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("View Macro Tests")
struct ViewMacroSwiftTests {
    let testMacros: [String: Macro.Type] = [
        "ViewMacro": ViewMacro.self,
    ]

    @Test("View macro generates properties and initializer")
    func viewMacroGeneratesPropertiesAndInitializer() {
        assertMacroExpansion(
            """
            @ViewMacro(module: ProductDetail.self)
            public struct ProductDetailView: ViewProtocol {
                public var body: some View {
                    Text(viewState.name)
                }
            }
            """,
            expandedSource: """
            public struct ProductDetailView: ViewProtocol {
                @Bindable var viewState: ProductDetail.ViewState
                let reducer: Reducer<ProductDetail.ViewModel>

                @MainActor
                public init(viewState: ProductDetail.ViewState, reducer: Reducer<ProductDetail.ViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }

                public var body: some View {
                    Text(viewState.name)
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("View macro only applies to struct")
    func viewMacroOnlyAppliesToStruct() {
        assertMacroExpansion(
            """
            @ViewMacro(module: ProductDetail.self)
            public class ProductDetailView {
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            expandedSource: """
            public class ProductDetailView {
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@View can only be applied to structs", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }

    @Test("View macro with complex body")
    func viewMacroWithComplexBody() {
        assertMacroExpansion(
            """
            @ViewMacro(module: ProductEdit.self)
            public struct ProductEditView: ViewProtocol {
                public var body: some View {
                    VStack {
                        Text(viewState.name)
                        Button("Save") {
                            reducer.callAsFunction(.onTapSave)
                        }
                    }
                }
            }
            """,
            expandedSource: """
            public struct ProductEditView: ViewProtocol {
                @Bindable var viewState: ProductEdit.ViewState
                let reducer: Reducer<ProductEdit.ViewModel>

                @MainActor
                public init(viewState: ProductEdit.ViewState, reducer: Reducer<ProductEdit.ViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }

                public var body: some View {
                    VStack {
                        Text(viewState.name)
                        Button("Save") {
                            reducer.callAsFunction(.onTapSave)
                        }
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
