//
// Copyright © 2025 Alexander Romanov
// ProductListViewModelSwiftTests.swift, created on 18.09.2025
//

import Foundation
import Testing
@testable import OversizeArchitecture

@Suite("Product List ViewModel Tests")
struct ProductListViewModelSwiftTests {

    private func createViewModel(
        input: ProductListInput?,
        output: ProductListOutput? = nil
    ) async -> (ProductListViewModel, ProductListViewState) {
        let state = await MainActor.run { ProductListViewState(input: input) }
        let viewModel = await ProductListViewModel(
            state: state,
            input: input,
            output: output
        )
        return (viewModel, state)
    }

    @Test("Initialization with all filter")
    func initializationWithAllFilter() async {
        let input = ProductListInput(filterType: .all)

        let (viewModel, _) = await createViewModel(input: input)

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    @Test("Initialization with favorites filter")
    func initializationWithFavoritesFilter() async {
        let input = ProductListInput(filterType: .favorites)

        let (viewModel, _) = await createViewModel(input: input)

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .favorites)
            #expect(state.title == "Favorites")
        }
    }

    @Test("Initialization with nil input defaults to all")
    func initializationWithNilInputDefaultsToAll() async {
        let (viewModel, _) = await createViewModel(input: nil)

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    @Test("All filter type cases work correctly", arguments: ProductListInput.FilterType.allCases)
    func allFilterTypeCasesWorkCorrectly(filterType: ProductListInput.FilterType) async {
        let input = ProductListInput(filterType: filterType)
        let (viewModel, _) = await createViewModel(input: input)

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == filterType)

            let expectedTitle = filterType == .all ? "All Products" : "Favorites"
            #expect(state.title == expectedTitle)
        }
    }

    @Test("OnAppear method maintains state")
    func onAppearMethodMaintainsState() async {
        let input = ProductListInput(filterType: .all)
        let (viewModel, _) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    @Test("ViewModel works with output")
    func viewModelWorksWithOutput() async {
        let input = ProductListInput(filterType: .all)
        let output = ProductListOutput()

        let (viewModel, _) = await createViewModel(input: input, output: output)

        await viewModel.onAppear()

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    @Test("ViewModel works without output")
    func viewModelWorksWithoutOutput() async {
        let input = ProductListInput(filterType: .favorites)
        let (viewModel, _) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .favorites)
            #expect(state.title == "Favorites")
        }
    }

    @Test("Multiple onAppear calls work correctly")
    func multipleOnAppearCallsWorkCorrectly() async {
        let input = ProductListInput(filterType: .all)
        let (viewModel, _) = await createViewModel(input: input, output: ProductListOutput())

        await viewModel.onAppear()
        await viewModel.onAppear()
        await viewModel.onAppear()

        await MainActor.run {
            let state = viewModel.state
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }
}