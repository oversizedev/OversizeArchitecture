//
// Copyright © 2025 Alexander Romanov
// ProductEditViewModelTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture

actor ProductBox {
    private var savedProducts: [Product] = []
    private var saveCallCount = 0

    func setProduct(_ product: Product?) {
        saveCallCount += 1
        if let product = product {
            savedProducts.append(product)
        }
    }

    func getLatestProduct() -> Product? {
        return savedProducts.last
    }

    func getAllProducts() -> [Product] {
        return savedProducts
    }

    func getSaveCallCount() -> Int {
        return saveCallCount
    }

    func reset() {
        savedProducts.removeAll()
        saveCallCount = 0
    }
}

final class ProductEditViewModelTests: XCTestCase {

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

    func testProductEditViewModelInitializationCreateMode() async {
        let input = ProductEditInput()

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            XCTAssertEqual(state.mode, .create)
            XCTAssertEqual(state.name, "")
            XCTAssertNotNil(state.productId)
        }
    }

    func testProductEditViewModelWithExistingProduct() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            XCTAssertEqual(state.mode, .edit)
            XCTAssertEqual(state.productId, product.id)
            XCTAssertEqual(state.name, "")
        }
    }

    func testProductEditViewModelInitializationWithId() async {
        let productId = UUID()
        let input = ProductEditInput(id: productId)

        let (_, state) = await createViewModel(input: input)

        await MainActor.run {
            XCTAssertEqual(state.mode, .edit)
            XCTAssertEqual(state.productId, productId)
            XCTAssertEqual(state.name, "")
        }
    }

    func testOnTapSaveCreateMode() async {
        let input = ProductEditInput()
        let productBox = ProductBox()

        let output = ProductEditOutput { product in
            Task { await productBox.setProduct(product) }
        }

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await MainActor.run {
            state.name = "New Product Name"
        }

        await viewModel.onTapSave()

        await Task.yield()

        let product = await productBox.getLatestProduct()
        XCTAssertNotNil(product)
        XCTAssertEqual(product?.name, "New Product Name")

        let stateProductId = await MainActor.run { state.productId }
        XCTAssertEqual(product?.id, stateProductId)
    }

    func testOnTapSaveEditMode() async {
        let existingProduct = Product(id: UUID(), name: "Original Name")
        let input = ProductEditInput(product: existingProduct)

        let (viewModel, state) = await createViewModel(input: input)

        await MainActor.run {
            state.name = "Updated Product Name"
        }

        await viewModel.onTapSave()

        await MainActor.run {
            XCTAssertEqual(state.name, "Updated Product Name")
            XCTAssertEqual(state.productId, existingProduct.id)
            XCTAssertEqual(state.mode, .edit)
        }
    }

    func testOnTapSaveWithoutOutput() async {
        let input = ProductEditInput()

        let (viewModel, state) = await createViewModel(input: input)

        await MainActor.run {
            state.name = "Test Product"
        }

        await viewModel.onTapSave()

        await MainActor.run {
            XCTAssertNotNil(state.productId)
        }
    }

    func testOnTapSaveWithEmptyName() async {
        let input = ProductEditInput()
        let productBox = ProductBox()

        let output = ProductEditOutput { product in
            Task { await productBox.setProduct(product) }
        }

        let (viewModel, state) = await createViewModel(input: input, output: output)

        await MainActor.run {
            state.name = ""
        }

        await viewModel.onTapSave()

        await Task.yield()

        let product = await productBox.getLatestProduct()
        XCTAssertNotNil(product)
        XCTAssertEqual(product?.name, "")
    }

    func testMultipleSaveCalls() async {
        let input = ProductEditInput()
        let productBox = ProductBox()

        let output = ProductEditOutput { product in
            Task { await productBox.setProduct(product) }
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

        let saveCount = await productBox.getSaveCallCount()
        let allProducts = await productBox.getAllProducts()

        XCTAssertEqual(saveCount, 2)
        XCTAssertEqual(allProducts.count, 2)
        XCTAssertEqual(allProducts.first?.name, "First Save")
        XCTAssertEqual(allProducts.last?.name, "Second Save")
    }

}