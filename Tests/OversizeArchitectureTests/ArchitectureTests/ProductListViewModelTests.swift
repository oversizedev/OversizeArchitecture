//
// Copyright © 2025 Alexander Romanov
// ProductListViewModelTests.swift, created on 18.09.2025
//

import Foundation
@testable import OversizeArchitecture
import OversizeArchitectureTesting
import Testing

@MainActor
struct ProductListViewModelTests {
    @Test("Initialization with all filter")
    func initializationWithAllFilter() {
        let host = ModuleTestHost<ProductList>(input: ProductListInput(filterType: .all))

        #expect(host.state.filterType == .all)
        #expect(host.state.title == "All Products")
    }

    @Test("Initialization with favorites filter")
    func initializationWithFavoritesFilter() {
        let host = ModuleTestHost<ProductList>(input: ProductListInput(filterType: .favorites))

        #expect(host.state.filterType == .favorites)
        #expect(host.state.title == "Favorites")
    }

    @Test("Initialization with nil input defaults to all")
    func initializationWithNilInputDefaultsToAll() {
        let host = ModuleTestHost<ProductList>()

        #expect(host.state.filterType == .all)
        #expect(host.state.title == "All Products")
    }

    @Test("All filter type cases work correctly", arguments: ProductListInput.FilterType.allCases)
    func allFilterTypeCasesWorkCorrectly(filterType: ProductListInput.FilterType) {
        let host = ModuleTestHost<ProductList>(input: ProductListInput(filterType: filterType))

        let expectedTitle = filterType == .all ? "All Products" : "Favorites"
        #expect(host.state.filterType == filterType)
        #expect(host.state.title == expectedTitle)
    }

    @Test("OnAppear action maintains state")
    func onAppearActionMaintainsState() async {
        let host = ModuleTestHost<ProductList>(input: ProductListInput(filterType: .all))

        await host.send(.onAppear)

        #expect(host.state.filterType == .all)
        #expect(host.state.title == "All Products")
    }

    @Test("ViewModel works with output")
    func viewModelWorksWithOutput() async {
        let host = ModuleTestHost<ProductList>(
            input: ProductListInput(filterType: .all),
            output: ProductListOutput()
        )

        await host.send(.onAppear)

        #expect(host.state.filterType == .all)
        #expect(host.state.title == "All Products")
    }

    @Test("ViewModel works without output")
    func viewModelWorksWithoutOutput() async {
        let host = ModuleTestHost<ProductList>(input: ProductListInput(filterType: .favorites))

        await host.send(.onAppear)

        #expect(host.state.filterType == .favorites)
        #expect(host.state.title == "Favorites")
    }

    @Test("Multiple onAppear actions work correctly")
    func multipleOnAppearActionsWorkCorrectly() async {
        let host = ModuleTestHost<ProductList>(
            input: ProductListInput(filterType: .all),
            output: ProductListOutput()
        )

        await host.send(.onAppear, .onAppear, .onAppear)

        #expect(host.state.filterType == .all)
        #expect(host.state.title == "All Products")
        #expect(host.reducer.pendingTaskCount == 0)
    }
}
