//
// Copyright © 2025 Alexander Romanov
// ProductListViewModelTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture


final class ProductListViewModelTests: XCTestCase {

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

    func testProductListViewModelInitializationWithAllFilter() async {
        let input = ProductListInput(filterType: .all)

        let (viewModel, _) = await createViewModel(input: input)

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .all)
            XCTAssertEqual(state.title, "All Products")
        }
    }

    func testProductListViewModelWithFavoritesFilter() async {
        let input = ProductListInput(filterType: .favorites)

        let (viewModel, _) = await createViewModel(input: input)

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .favorites)
            XCTAssertEqual(state.title, "Favorites")
        }
    }

    func testProductListViewModelWithNilInput() async {
        let (viewModel, _) = await createViewModel(input: nil)

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .all)
            XCTAssertEqual(state.title, "All Products")
        }
    }

    func testAllFilterTypeCases() async {
        for filterType in ProductListInput.FilterType.allCases {
            let input = ProductListInput(filterType: filterType)
            let (viewModel, _) = await createViewModel(input: input)

            let state = viewModel.state
            await MainActor.run {
                XCTAssertEqual(state.filterType, filterType)

                let expectedTitle = filterType == .all ? "All Products" : "Favorites"
                XCTAssertEqual(state.title, expectedTitle)
            }
        }
    }

    func testOnAppearMethod() async {
        let input = ProductListInput(filterType: .all)
        let (viewModel, _) = await createViewModel(input: input)

        await viewModel.onAppear()

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .all)
            XCTAssertEqual(state.title, "All Products")
        }
    }

    func testWithOutput() async {
        let input = ProductListInput(filterType: .all)
        let output = ProductListOutput()

        let (viewModel, _) = await createViewModel(input: input, output: output)

        await viewModel.onAppear()

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .all)
            XCTAssertEqual(state.title, "All Products")
        }
    }

    func testWithNilOutput() async {
        let input = ProductListInput(filterType: .favorites)
        let (viewModel, _) = await createViewModel(input: input)

        await viewModel.onAppear()

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .favorites)
            XCTAssertEqual(state.title, "Favorites")
        }
    }

    func testMultipleOnAppearCalls() async {
        let input = ProductListInput(filterType: .all)
        let (viewModel, _) = await createViewModel(input: input, output: ProductListOutput())

        await viewModel.onAppear()
        await viewModel.onAppear()
        await viewModel.onAppear()

        let state = viewModel.state
        await MainActor.run {
            XCTAssertEqual(state.filterType, .all)
            XCTAssertEqual(state.title, "All Products")
        }
    }

}