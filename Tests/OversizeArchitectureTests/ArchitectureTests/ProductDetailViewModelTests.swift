//
// Copyright © 2025 Alexander Romanov
// ProductDetailViewModelTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture


final class ProductDetailViewModelTests: XCTestCase {

    private func createViewModel(
        input: ProductDetailInput?,
        output: ProductDetailOutput? = nil
    ) async -> (ProductDetailViewModel, ProductDetailViewState) {
        let state = await MainActor.run { ProductDetailViewState(input: input) }
        let viewModel = await MainActor.run {
            ProductDetailViewModel(
                state: state,
                input: input,
                output: output
            )
        }
        return (viewModel, state)
    }

    func testProductDetailViewModelInitialization() async {
        let productId = UUID()
        let input = ProductDetailInput(id: productId)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            XCTAssertEqual(state.id, productId)
            XCTAssertEqual(state.name, "Product")
        }
    }

    func testProductDetailViewModelInitializationWithProduct() async {
        let product = Product(id: UUID(), name: "Initial Product")
        let input = ProductDetailInput(product: product)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            XCTAssertEqual(state.id, product.id)
            XCTAssertEqual(state.name, "Product")
        }
    }

    func testOnAppearWithProductId() async {
        let productId = UUID()
        let input = ProductDetailInput(id: productId)

        let (viewModel, state) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            XCTAssertEqual(state.id, productId)
            XCTAssertEqual(state.name, "Loaded Product")
        }
    }

    func testOnAppearWithProduct() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductDetailInput(product: product)

        let (viewModel, state) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            XCTAssertEqual(state.id, product.id)
            XCTAssertEqual(state.name, "Test Product")
        }
    }

    func testOnAppearWithNilInput() async {
        let (viewModel, state) = await createViewModel(input: nil)

        await viewModel.onAppear()

        await MainActor.run {
            XCTAssertEqual(state.name, "Product")
            XCTAssertNotNil(state.id)
        }
    }

    func testWithOutput() async {
        let product = Product(id: UUID(), name: "Output Test Product")
        let input = ProductDetailInput(product: product)
        let output = ProductDetailOutput()

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await viewModel.onAppear()

        await MainActor.run {
            XCTAssertEqual(state.id, product.id)
            XCTAssertEqual(state.name, product.name)
        }
    }

}