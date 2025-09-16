//
// Copyright © 2025 Alexander Romanov
// ScreenMacroTests.swift, created on 17.09.2025
//

import OversizeArchitecture
import OversizeArchitectureMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ScreenMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "Screen": ScreenMacro.self,
    ]

    func testMultipleBuildTypes() throws {
        assertMacroExpansion(
            """
            @Screen(.default, .id)
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            expandedSource: """
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building TestScreen")
                    let viewState = TestViewState()
                    let viewModel = TestViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return TestScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building TestScreen for ID: \\(id)")
                    let viewState = TestViewState(id: id)
                    let viewModel = TestViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return TestScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testSimpleBuild() throws {
        assertMacroExpansion(
            """
            @Screen
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            expandedSource: """
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building TestScreen")
                    let viewState = TestViewState()
                    let viewModel = TestViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return TestScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testIdBuild() throws {
        assertMacroExpansion(
            """
            @Screen(.id)
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            expandedSource: """
            public struct TestScreen: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building TestScreen for ID: \\(id)")
                    let viewState = TestViewState(id: id)
                    let viewModel = TestViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return TestScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testScreenWithoutScreenSuffix() throws {
        assertMacroExpansion(
            """
            @Screen
            public struct HomePage: ViewProtocol {
                @Bindable var viewState: HomePageViewState
                let reducer: Reducer<HomePageViewModel>
                
                public init(viewState: HomePageViewState, reducer: Reducer<HomePageViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Home")
                }
            }
            """,
            expandedSource: """
            public struct HomePage: ViewProtocol {
                @Bindable var viewState: HomePageViewState
                let reducer: Reducer<HomePageViewModel>
                
                public init(viewState: HomePageViewState, reducer: Reducer<HomePageViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Home")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building HomePage")
                    let viewState = HomePageViewState()
                    let viewModel = HomePageViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return HomePage(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testComplexScreenName() throws {
        assertMacroExpansion(
            """
            @Screen(.default, .id)
            public struct UserProfileEditScreen: ViewProtocol {
                @Bindable var viewState: UserProfileEditViewState
                let reducer: Reducer<UserProfileEditViewModel>
                
                public init(viewState: UserProfileEditViewState, reducer: Reducer<UserProfileEditViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    VStack {
                        Text("User Profile Edit")
                    }
                }
            }
            """,
            expandedSource: """
            public struct UserProfileEditScreen: ViewProtocol {
                @Bindable var viewState: UserProfileEditViewState
                let reducer: Reducer<UserProfileEditViewModel>
                
                public init(viewState: UserProfileEditViewState, reducer: Reducer<UserProfileEditViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    VStack {
                        Text("User Profile Edit")
                    }
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building UserProfileEditScreen")
                    let viewState = UserProfileEditViewState()
                    let viewModel = UserProfileEditViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return UserProfileEditScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building UserProfileEditScreen for ID: \\(id)")
                    let viewState = UserProfileEditViewState(id: id)
                    let viewModel = UserProfileEditViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return UserProfileEditScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testScreenOnlyAppliesToStruct() throws {
        assertMacroExpansion(
            """
            @Screen
            public class TestScreenClass: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            expandedSource: """
            public class TestScreenClass: ViewProtocol {
                @Bindable var viewState: TestViewState
                let reducer: Reducer<TestViewModel>
                
                public init(viewState: TestViewState, reducer: Reducer<TestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Test")
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Screen can only be applied to structs", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }

    func testScreenOnlyAppliesToStructEnum() throws {
        assertMacroExpansion(
            """
            @Screen
            public enum TestScreenEnum {
                case home
                case profile
            }
            """,
            expandedSource: """
            public enum TestScreenEnum {
                case home
                case profile
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@Screen can only be applied to structs", line: 1, column: 1, severity: .error)
            ],
            macros: testMacros
        )
    }

    func testInternalScreenStruct() throws {
        assertMacroExpansion(
            """
            @Screen
            struct InternalTestScreen: ViewProtocol {
                @Bindable var viewState: InternalTestViewState
                let reducer: Reducer<InternalTestViewModel>
                
                init(viewState: InternalTestViewState, reducer: Reducer<InternalTestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                var body: some View {
                    Text("Internal Test")
                }
            }
            """,
            expandedSource: """
            struct InternalTestScreen: ViewProtocol {
                @Bindable var viewState: InternalTestViewState
                let reducer: Reducer<InternalTestViewModel>
                
                init(viewState: InternalTestViewState, reducer: Reducer<InternalTestViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                var body: some View {
                    Text("Internal Test")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building InternalTestScreen")
                    let viewState = InternalTestViewState()
                    let viewModel = InternalTestViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return InternalTestScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testBuildMethodsWithRealWorldExample() throws {
        assertMacroExpansion(
            """
            @Screen(.default, .id)
            public struct AuthenticationScreen: ViewProtocol {
                @Bindable var viewState: AuthenticationViewState
                let reducer: Reducer<AuthenticationViewModel>
                
                public init(viewState: AuthenticationViewState, reducer: Reducer<AuthenticationViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Form {
                        TextField("Email", text: $viewState.email)
                        SecureField("Password", text: $viewState.password)
                        Button("Sign In") {
                            reducer.handleAction(.onSignInTapped)
                        }
                    }
                }
            }
            """,
            expandedSource: """
            public struct AuthenticationScreen: ViewProtocol {
                @Bindable var viewState: AuthenticationViewState
                let reducer: Reducer<AuthenticationViewModel>
                
                public init(viewState: AuthenticationViewState, reducer: Reducer<AuthenticationViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Form {
                        TextField("Email", text: $viewState.email)
                        SecureField("Password", text: $viewState.password)
                        Button("Sign In") {
                            reducer.handleAction(.onSignInTapped)
                        }
                    }
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building AuthenticationScreen")
                    let viewState = AuthenticationViewState()
                    let viewModel = AuthenticationViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return AuthenticationScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building AuthenticationScreen for ID: \\(id)")
                    let viewState = AuthenticationViewState(id: id)
                    let viewModel = AuthenticationViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return AuthenticationScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testDuplicateBuildTypesShouldBeHandled() throws {
        assertMacroExpansion(
            """
            @Screen(.default, .default, .id)
            public struct DuplicateScreen: ViewProtocol {
                @Bindable var viewState: DuplicateViewState
                let reducer: Reducer<DuplicateViewModel>
                
                public init(viewState: DuplicateViewState, reducer: Reducer<DuplicateViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Duplicate")
                }
            }
            """,
            expandedSource: """
            public struct DuplicateScreen: ViewProtocol {
                @Bindable var viewState: DuplicateViewState
                let reducer: Reducer<DuplicateViewModel>
                
                public init(viewState: DuplicateViewState, reducer: Reducer<DuplicateViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Duplicate")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building DuplicateScreen")
                    let viewState = DuplicateViewState()
                    let viewModel = DuplicateViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return DuplicateScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building DuplicateScreen for ID: \\(id)")
                    let viewState = DuplicateViewState(id: id)
                    let viewModel = DuplicateViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return DuplicateScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testSingleCharacterScreenName() throws {
        assertMacroExpansion(
            """
            @Screen
            public struct AScreen: ViewProtocol {
                @Bindable var viewState: AViewState
                let reducer: Reducer<AViewModel>
                
                public init(viewState: AViewState, reducer: Reducer<AViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("A")
                }
            }
            """,
            expandedSource: """
            public struct AScreen: ViewProtocol {
                @Bindable var viewState: AViewState
                let reducer: Reducer<AViewModel>
                
                public init(viewState: AViewState, reducer: Reducer<AViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("A")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building AScreen")
                    let viewState = AViewState()
                    let viewModel = AViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return AScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testScreenWithDifferentAccessModifiers() throws {
        assertMacroExpansion(
            """
            @Screen
            struct PrivateScreen: ViewProtocol {
                @Bindable var viewState: PrivateViewState
                let reducer: Reducer<PrivateViewModel>
                
                init(viewState: PrivateViewState, reducer: Reducer<PrivateViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                var body: some View {
                    Text("Private")
                }
            }
            """,
            expandedSource: """
            struct PrivateScreen: ViewProtocol {
                @Bindable var viewState: PrivateViewState
                let reducer: Reducer<PrivateViewModel>
                
                init(viewState: PrivateViewState, reducer: Reducer<PrivateViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                var body: some View {
                    Text("Private")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building PrivateScreen")
                    let viewState = PrivateViewState()
                    let viewModel = PrivateViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return PrivateScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testOnlyIdBuildTypeExplicit() throws {
        assertMacroExpansion(
            """
            @Screen(.id)
            public struct OnlyIdScreen: ViewProtocol {
                @Bindable var viewState: OnlyIdViewState
                let reducer: Reducer<OnlyIdViewModel>
                
                public init(viewState: OnlyIdViewState, reducer: Reducer<OnlyIdViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Only ID")
                }
            }
            """,
            expandedSource: """
            public struct OnlyIdScreen: ViewProtocol {
                @Bindable var viewState: OnlyIdViewState
                let reducer: Reducer<OnlyIdViewModel>
                
                public init(viewState: OnlyIdViewState, reducer: Reducer<OnlyIdViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Only ID")
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building OnlyIdScreen for ID: \\(id)")
                    let viewState = OnlyIdViewState(id: id)
                    let viewModel = OnlyIdViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return OnlyIdScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testScreenWithGenericConstraints() throws {
        assertMacroExpansion(
            """
            @Screen
            public struct GenericScreen<T>: ViewProtocol where T: Equatable {
                @Bindable var viewState: GenericViewState
                let reducer: Reducer<GenericViewModel>
                
                public init(viewState: GenericViewState, reducer: Reducer<GenericViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Generic")
                }
            }
            """,
            expandedSource: """
            public struct GenericScreen<T>: ViewProtocol where T: Equatable {
                @Bindable var viewState: GenericViewState
                let reducer: Reducer<GenericViewModel>
                
                public init(viewState: GenericViewState, reducer: Reducer<GenericViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Generic")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building GenericScreen")
                    let viewState = GenericViewState()
                    let viewModel = GenericViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return GenericScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testReversedBuildTypesOrder() throws {
        assertMacroExpansion(
            """
            @Screen(.id, .default)
            public struct ReversedScreen: ViewProtocol {
                @Bindable var viewState: ReversedViewState
                let reducer: Reducer<ReversedViewModel>
                
                public init(viewState: ReversedViewState, reducer: Reducer<ReversedViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Reversed")
                }
            }
            """,
            expandedSource: """
            public struct ReversedScreen: ViewProtocol {
                @Bindable var viewState: ReversedViewState
                let reducer: Reducer<ReversedViewModel>
                
                public init(viewState: ReversedViewState, reducer: Reducer<ReversedViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Reversed")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building ReversedScreen")
                    let viewState = ReversedViewState()
                    let viewModel = ReversedViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return ReversedScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building ReversedScreen for ID: \\(id)")
                    let viewState = ReversedViewState(id: id)
                    let viewModel = ReversedViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return ReversedScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testEmptyScreenStruct() throws {
        assertMacroExpansion(
            """
            @Screen
            public struct EmptyScreen: ViewProtocol {
                public var body: some View {
                    EmptyView()
                }
            }
            """,
            expandedSource: """
            public struct EmptyScreen: ViewProtocol {
                public var body: some View {
                    EmptyView()
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building EmptyScreen")
                    let viewState = EmptyViewState()
                    let viewModel = EmptyViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return EmptyScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }

    func testScreenWithComplexInheritance() throws {
        assertMacroExpansion(
            """
            @Screen(.default, .id)
            public struct ComplexInheritanceScreen: ViewProtocol, Equatable, Hashable {
                @Bindable var viewState: ComplexInheritanceViewState
                let reducer: Reducer<ComplexInheritanceViewModel>
                
                public init(viewState: ComplexInheritanceViewState, reducer: Reducer<ComplexInheritanceViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Complex")
                }
            }
            """,
            expandedSource: """
            public struct ComplexInheritanceScreen: ViewProtocol, Equatable, Hashable {
                @Bindable var viewState: ComplexInheritanceViewState
                let reducer: Reducer<ComplexInheritanceViewModel>
                
                public init(viewState: ComplexInheritanceViewState, reducer: Reducer<ComplexInheritanceViewModel>) {
                    self.viewState = viewState
                    self.reducer = reducer
                }
                
                public var body: some View {
                    Text("Complex")
                }

                @MainActor
                public static func build() -> some View {
                    logNotice("Building ComplexInheritanceScreen")
                    let viewState = ComplexInheritanceViewState()
                    let viewModel = ComplexInheritanceViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return ComplexInheritanceScreen(viewState: viewState, reducer: reducer)
                }

                @MainActor
                public static func build(id: UUID) -> some View {
                    logNotice("Building ComplexInheritanceScreen for ID: \\(id)")
                    let viewState = ComplexInheritanceViewState(id: id)
                    let viewModel = ComplexInheritanceViewModel(state: viewState)
                    let reducer = Reducer(viewModel: viewModel)
                    return ComplexInheritanceScreen(viewState: viewState, reducer: reducer)
                }
            }
            """,
            macros: testMacros
        )
    }
}
