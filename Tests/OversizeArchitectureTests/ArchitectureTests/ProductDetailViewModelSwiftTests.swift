//
// Copyright © 2025 Alexander Romanov
// ProductDetailViewModelSwiftTests.swift, created on 18.09.2025
//

import Foundation
import Testing
@testable import OversizeArchitecture

@Suite("Product Detail ViewModel Tests")
struct ProductDetailViewModelSwiftTests {

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

    @Test("ViewModel initialization with product ID")
    func viewModelInitializationWithProductId() async {
        let productId = UUID()
        let input = ProductDetailInput(id: productId)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            #expect(state.id == productId)
            #expect(state.name == "Product")
        }
    }

    @Test("ViewModel initialization with product")
    func viewModelInitializationWithProduct() async {
        let product = Product(id: UUID(), name: "Initial Product")
        let input = ProductDetailInput(product: product)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            #expect(state.id == product.id)
            #expect(state.name == "Product")
        }
    }

    @Test("OnAppear with product ID loads product")
    func onAppearWithProductIdLoadsProduct() async {
        let productId = UUID()
        let input = ProductDetailInput(id: productId)

        let (viewModel, state) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            #expect(state.id == productId)
            #expect(state.name == "Loaded Product")
        }
    }

    @Test("OnAppear with product keeps product name")
    func onAppearWithProductKeepsProductName() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductDetailInput(product: product)

        let (viewModel, state) = await createViewModel(input: input)

        await viewModel.onAppear()

        await MainActor.run {
            #expect(state.id == product.id)
            #expect(state.name == "Test Product")
        }
    }

    @Test("OnAppear with nil input creates default state")
    func onAppearWithNilInputCreatesDefaultState() async {
        let (viewModel, state) = await createViewModel(input: nil)

        await viewModel.onAppear()

        await MainActor.run {
            #expect(state.name == "Product")
        }
    }

    @Test("ViewModel works with output")
    func viewModelWorksWithOutput() async {
        let product = Product(id: UUID(), name: "Output Test Product")
        let input = ProductDetailInput(product: product)
        let output = ProductDetailOutput()

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await viewModel.onAppear()

        await MainActor.run {
            #expect(state.id == product.id)
            #expect(state.name == product.name)
        }
    }
}