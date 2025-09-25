//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModelTests.swift, created on 18.09.2025
//

import Foundation
@testable import OversizeArchitecture
import Testing

actor ProductTestCapture {
    private var savedProducts: [Product] = []
    private var saveCallCount = 0

    func setProduct(_ product: Product?) {
        saveCallCount += 1
        if let product {
            savedProducts.append(product)
        }
    }

    func getLatestProduct() -> Product? {
        savedProducts.last
    }

    func getAllProducts() -> [Product] {
        savedProducts
    }

    func getSaveCallCount() -> Int {
        saveCallCount
    }

    func reset() {
        savedProducts.removeAll()
        saveCallCount = 0
    }
}

@Suite("Product Edit ViewModel Tests")
struct ProductEditViewModelTests {
    private func createViewModel(
        input: ProductEditInput?,
        output: ProductEditOutput? = nil
    ) async -> (ProductEditViewModel, ProductEditViewState) {
        let state = await MainActor.run { ProductEditViewState(input: input) }
        let viewModel = await MainActor.run {
            ProductEditViewModel(
                state: state,
                input: input,
                output: output
            )
        }
        return (viewModel, state)
    }

    @Test("Initialization in create mode")
    func initializationInCreateMode() async {
        let input = ProductEditInput()

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.create)
            #expect(state.name == "")
        }
    }

    @Test("Initialization with existing product")
    func initializationWithExistingProduct() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.edit)
            #expect(state.productId == product.id)
            #expect(state.name == "")
        }
    }

    @Test("Initialization with product ID")
    func initializationWithProductId() async {
        let productId = UUID()
        let input = ProductEditInput(id: productId)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.edit)
            #expect(state.productId == productId)
            #expect(state.name == "")
        }
    }

    @Test("OnTapSave in create mode with output")
    func onTapSaveInCreateModeWithOutput() async {
        let input = ProductEditInput()
        let productCapture = ProductTestCapture()

        let output = ProductEditOutput { product in
            Task { await productCapture.setProduct(product) }
        }

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await MainActor.run {
            state.name = "New Product Name"
        }

        await viewModel.onTapSave()
        await Task.yield()

        let product = await productCapture.getLatestProduct()
        #expect(product != nil)
        #expect(product?.name == "New Product Name")

        let stateProductId = await MainActor.run { state.productId }
        #expect(product?.id == stateProductId)
    }

    @Test("OnTapSave in edit mode")
    func onTapSaveInEditMode() async {
        let existingProduct = Product(id: UUID(), name: "Original Name")
        let input = ProductEditInput(product: existingProduct)

        let (viewModel, state) = await createViewModel(input: input)

        await MainActor.run {
            state.name = "Updated Product Name"
        }

        await viewModel.onTapSave()

        await MainActor.run {
            #expect(state.name == "Updated Product Name")
            #expect(state.productId == existingProduct.id)
            #expect(state.mode == ProductEditViewState.EditMode.edit)
        }
    }

    @Test("OnTapSave without output")
    func onTapSaveWithoutOutput() async {
        let input = ProductEditInput()

        let (viewModel, state) = await createViewModel(input: input)

        await MainActor.run {
            state.name = "Test Product"
        }

        await viewModel.onTapSave()

        await MainActor.run {}
    }

    @Test("OnTapSave with empty name")
    func onTapSaveWithEmptyName() async {
        let input = ProductEditInput()
        let productCapture = ProductTestCapture()

        let output = ProductEditOutput { product in
            Task { await productCapture.setProduct(product) }
        }

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await MainActor.run {
            state.name = ""
        }

        await viewModel.onTapSave()
        await Task.yield()

        let product = await productCapture.getLatestProduct()
        #expect(product != nil)
        #expect(product?.name == "")
    }

    @Test("Multiple save calls")
    func multipleSaveCalls() async {
        let input = ProductEditInput()
        let productCapture = ProductTestCapture()

        let output = ProductEditOutput { product in
            Task { await productCapture.setProduct(product) }
        }

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await MainActor.run {
            state.name = "First Save"
        }
        await viewModel.onTapSave()

        await MainActor.run {
            state.name = "Second Save"
        }
        await viewModel.onTapSave()

        await Task.yield()

        let saveCount = await productCapture.getSaveCallCount()
        let allProducts = await productCapture.getAllProducts()

        #expect(saveCount == 2)
        #expect(allProducts.count == 2)
        #expect(allProducts.first?.name == "First Save")
        #expect(allProducts.last?.name == "Second Save")
    }
}
