//
// Copyright © 2025 Alexander Romanov
// ViewModelMacroSwiftTests.swift, created on 18.09.2025
//

import Foundation
import OversizeArchitecture
import OversizeArchitectureMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing

@Suite("ViewModel Macro Tests")
struct ViewModelMacroSwiftTests {
    let testMacros: [String: Macro.Type] = [
        "ViewModelMacro": ViewModelMacro.self,
    ]

    @Test("Simple on methods generate actions")
    func simpleOnMethodsGenerateActions() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onTapSave() async {}
                func onDisappear() async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onTapSave() async {}
                func onDisappear() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case .onTapSave:
                        await onTapSave()
                    case .onDisappear:
                        await onDisappear()
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onTapSave
                    case onDisappear
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("On methods with parameters generate actions with associated values")
    func onMethodsWithParametersGenerateActionsWithAssociatedValues() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onNameChanged(name: String) async {}
                func onValueChanged(_ value: Int) async {}
                func onFocusField(_ field: TestViewState.FocusField?) async {}
                func onUpdateData(id: UUID, name: String) async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onNameChanged(name: String) async {}
                func onValueChanged(_ value: Int) async {}
                func onFocusField(_ field: TestViewState.FocusField?) async {}
                func onUpdateData(id: UUID, name: String) async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case let .onNameChanged(name):
                        await onNameChanged(name: name)
                    case let .onValueChanged(value):
                        await onValueChanged(value)
                    case let .onFocusField(field):
                        await onFocusField(field)
                    case let .onUpdateData(id, name):
                        await onUpdateData(id: id, name: name)
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onNameChanged(name: String)
                    case onValueChanged(Int)
                    case onFocusField(TestViewState.FocusField?)
                    case onUpdateData(id: UUID, name: String)
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Private on methods are ignored")
    func privateOnMethodsAreIgnored() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                private func onPrivateMethod() async {}
                func onSave() async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                private func onPrivateMethod() async {}
                func onSave() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case .onSave:
                        await onSave()
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onSave
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Non-on methods are ignored")
    func nonOnMethodsAreIgnored() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func handleAction(_ action: Action) async {}
                func save() async {}
                func load() async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func handleAction(_ action: Action) async {}
                func save() async {}
                func load() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onAppear
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Class support")
    func classSupport() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public class TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onSave() async {}
            }
            """,
            expandedSource: """
            public class TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onSave() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case .onSave:
                        await onSave()
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onSave
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Empty actor generates empty enum")
    func emptyActorGeneratesEmptyEnum() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func save() async {}
                func load() async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func save() async {}
                func load() async {}

                public func handleAction(_ action: Action) async {
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Macro only applies to class and actor")
    func macroOnlyAppliesToClassAndActor() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public struct TestStruct {
                func onAppear() async {}
            }
            """,
            expandedSource: """
            public struct TestStruct {
                func onAppear() async {}
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ViewModelMacro can only be applied to classes or actors", line: 1, column: 1, severity: .error),
                DiagnosticSpec(message: "@ViewModelMacro can only be applied to classes or actors", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }

    @Test("Complex parameter labels")
    func complexParameterLabels() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onSet(value newValue: String) async {}
                func onUpdate(at index: Int, with value: String) async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onSet(value newValue: String) async {}
                func onUpdate(at index: Int, with value: String) async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case let .onSet(value):
                        await onSet(value: value)
                    case let .onUpdate(at, with):
                        await onUpdate(at: at, with: with)
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onSet(value: String)
                    case onUpdate(at: Int, with: String)
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Real world example")
    func realWorldExample() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor MealProductCategoryEditViewModel: ViewModelProtocol {
                public var state: MealProductCategoryEditViewState

                public init(state: MealProductCategoryEditViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onTapSave() async {}
                func onFocusField(_ field: MealProductCategoryEditViewState.FocusField?) async {}
                func onNameChanged(name: String) async {}
                func onNoteChanged(note: String) async {}
                func onUrlChanged(url: URL?) async {}
                private func updateFormValidation() async {}
            }
            """,
            expandedSource: """
            public actor MealProductCategoryEditViewModel: ViewModelProtocol {
                public var state: MealProductCategoryEditViewState

                public init(state: MealProductCategoryEditViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onTapSave() async {}
                func onFocusField(_ field: MealProductCategoryEditViewState.FocusField?) async {}
                func onNameChanged(name: String) async {}
                func onNoteChanged(note: String) async {}
                func onUrlChanged(url: URL?) async {}
                private func updateFormValidation() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case .onTapSave:
                        await onTapSave()
                    case let .onFocusField(field):
                        await onFocusField(field)
                    case let .onNameChanged(name):
                        await onNameChanged(name: name)
                    case let .onNoteChanged(note):
                        await onNoteChanged(note: note)
                    case let .onUrlChanged(url):
                        await onUrlChanged(url: url)
                    }
                }
            }

            extension MealProductCategoryEditViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onTapSave
                    case onFocusField(MealProductCategoryEditViewState.FocusField?)
                    case onNameChanged(name: String)
                    case onNoteChanged(note: String)
                    case onUrlChanged(url: URL?)
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Handle action method generation")
    func handleActionMethodGeneration() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onSave(name: String) async {}
                func onDelete(_ id: UUID) async {}
            }
            """,
            expandedSource: """
            public actor TestViewModel: ViewModelProtocol {
                public var state: TestViewState

                public init(state: TestViewState) {
                    self.state = state
                }

                func onAppear() async {}
                func onSave(name: String) async {}
                func onDelete(_ id: UUID) async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case let .onSave(name):
                        await onSave(name: name)
                    case let .onDelete(id):
                        await onDelete(id)
                    }
                }
            }

            extension TestViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onSave(name: String)
                    case onDelete(UUID)
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("Empty ViewModel handle action")
    func emptyViewModelHandleAction() {
        assertMacroExpansion(
            """
            @ViewModelMacro
            public actor EmptyViewModel: ViewModelProtocol {
                public var state: EmptyViewState

                public init(state: EmptyViewState) {
                    self.state = state
                }
            }
            """,
            expandedSource: """
            public actor EmptyViewModel: ViewModelProtocol {
                public var state: EmptyViewState

                public init(state: EmptyViewState) {
                    self.state = state
                }

                public func handleAction(_ action: Action) async {
                }
            }

            extension EmptyViewModel {
                public enum Action: Sendable {
                }
            }
            """,
            macros: testMacros
        )
    }

    @Test("ViewModel with module generates properties and initializer")
    func viewModelWithModuleGeneratesPropertiesAndInitializer() {
        assertMacroExpansion(
            """
            @ViewModelMacro(module: ProductEditModule.self)
            public actor ProductEditViewModel: ViewModelProtocol {
                func onAppear() async {}
                func onTapSave() async {}
            }
            """,
            expandedSource: """
            public actor ProductEditViewModel: ViewModelProtocol {
                @MainActor
                public var state: ProductEditModule.ViewState
                private let input: ProductEditModule.Input?
                private let output: ProductEditModule.Output?

                @MainActor
                public init(state: ProductEditModule.ViewState, input: ProductEditModule.Input?, output: ProductEditModule.Output?) {
                    self.state = state
                    self.input = input
                    self.output = output
                }

                func onAppear() async {}
                func onTapSave() async {}

                public func handleAction(_ action: Action) async {
                    switch action {
                    case .onAppear:
                        await onAppear()
                    case .onTapSave:
                        await onTapSave()
                    }
                }
            }

            extension ProductEditViewModel {
                public enum Action: Sendable {
                    case onAppear
                    case onTapSave
                }
            }
            """,
            macros: testMacros
        )
    }
}
