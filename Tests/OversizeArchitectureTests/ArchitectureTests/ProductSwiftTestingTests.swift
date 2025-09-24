//
// Copyright © 2025 Alexander Romanov
// ProductSwiftTestingTests.swift, created on 18.09.2025
//

import Foundation
@testable import OversizeArchitecture
import Testing

@Suite("Product Swift Testing Demo")
struct ProductSwiftTestingTests {
    @Test("Product initialization")
    func productInitialization() {
        let id = UUID()
        let name = "Test Product"

        let product = Product(id: id, name: name)

        #expect(product.id == id)
        #expect(product.name == name)
    }

    @Test("Product equality")
    func productEquality() {
        let id = UUID()
        let product1 = Product(id: id, name: "Product 1")
        let product2 = Product(id: id, name: "Product 2")
        let product3 = Product(id: UUID(), name: "Product 1")

        #expect(product1.id == product2.id) // Same id
        #expect(product1.id != product3.id) // Different id
        #expect(product1.name == "Product 1")
        #expect(product2.name == "Product 2")
    }

    @Test("Product list filter types", arguments: [
        ProductListInput.FilterType.all,
        ProductListInput.FilterType.favorites
    ])
    func filterTypeTests(filterType: ProductListInput.FilterType) {
        let input = ProductListInput(filterType: filterType)

        #expect(input.filterType == filterType)

        switch filterType {
        case .all:
            #expect(input.filterType.title == "All Products")
        case .favorites:
            #expect(input.filterType.title == "Favorites")
        }
    }

    @Test("Product detail input with different sources")
    func productDetailInputSources() async {
        let productId = UUID()
        let product = Product(id: productId, name: "Test Product")

        // Test with ID
        let inputWithId = ProductDetailInput(id: productId)
        #expect(inputWithId.productId == productId)

        // Test with product
        let inputWithProduct = ProductDetailInput(product: product)
        #expect(inputWithProduct.productId == product.id)
    }

    @Test("Product edit input modes")
    func productEditInputModes() async {
        // Create mode
        let createInput = ProductEditInput()
        let createState = await MainActor.run {
            ProductEditViewState(input: createInput)
        }

        await MainActor.run {
            #expect(createState.mode == ProductEditViewState.EditMode.create)
            #expect(createState.name == "")
        }

        // Edit mode with product
        let product = Product(id: UUID(), name: "Edit Product")
        let editInput = ProductEditInput(product: product)
        let editState = await MainActor.run {
            ProductEditViewState(input: editInput)
        }

        await MainActor.run {
            #expect(editState.mode == ProductEditViewState.EditMode.edit)
            #expect(editState.productId == product.id)
            #expect(editState.name == "")
        }
    }

    @Test("Product list view state initialization")
    func productListViewStateInitialization() async {
        // Test with all filter
        let allInput = ProductListInput(filterType: .all)
        let allState = await MainActor.run {
            ProductListViewState(input: allInput)
        }

        await MainActor.run {
            #expect(allState.filterType == .all)
            #expect(allState.title == "All Products")
        }

        // Test with favorites filter
        let favoritesInput = ProductListInput(filterType: .favorites)
        let favoritesState = await MainActor.run {
            ProductListViewState(input: favoritesInput)
        }

        await MainActor.run {
            #expect(favoritesState.filterType == .favorites)
            #expect(favoritesState.title == "Favorites")
        }
    }
}

// MARK: - Tags for test organization

extension Tag {
    @Tag static var product: Self
    @Tag static var viewModel: Self
    @Tag static var async: Self
}

@Suite("Tagged Tests Demo", .tags(.product, .async))
struct TaggedProductTests {
    @Test("Async product creation", .tags(.product))
    func asyncProductCreation() async {
        let product = await Task {
            Product(id: UUID(), name: "Async Product")
        }.value

        #expect(product.name == "Async Product")
    }

    @Test("Multiple products comparison", .tags(.product))
    func multipleProductsComparison() {
        let products = (1 ... 5).map { index in
            Product(id: UUID(), name: "Product \(index)")
        }

        #expect(products.count == 5)

        let uniqueIds = Set(products.map { $0.id })
        #expect(uniqueIds.count == 5)

        for (index, product) in products.enumerated() {
            #expect(product.name == "Product \(index + 1)")
        }
    }
}
