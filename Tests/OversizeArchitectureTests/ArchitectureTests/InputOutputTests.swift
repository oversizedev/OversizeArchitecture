//
// Copyright © 2025 Alexander Romanov
// InputOutputTests.swift, created on 18.09.2025
//

import Foundation
@testable import OversizeArchitecture
import Testing

@Suite("Input Output Tests")
struct InputOutputTests {
    // MARK: - Product Detail Input Tests

    @Test("ProductDetailInput with ID")
    func productDetailInputWithId() {
        let id = UUID()
        let input = ProductDetailInput(id: id)

        #expect(input.productId == id)
    }

    @Test("ProductDetailInput with Product")
    func productDetailInputWithProduct() {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductDetailInput(product: product)

        #expect(input.productId == product.id)
    }

    // MARK: - Product Edit Input Tests

    @Test("ProductEditInput empty initialization")
    func productEditInputEmpty() {
        let input = ProductEditInput()

        #expect(input.productId == nil)
    }

    @Test("ProductEditInput with ID")
    func productEditInputWithId() {
        let id = UUID()
        let input = ProductEditInput(id: id)

        #expect(input.productId == id)
    }

    @Test("ProductEditInput with Product")
    func productEditInputWithProduct() {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)

        #expect(input.productId == product.id)
    }

    @Test("ProductEditOutput callback execution")
    func productEditOutputCallbackExecution() async {
        let capturedProduct = ActorBox<Product?>(nil)

        let output = ProductEditOutput { product in
            Task { await capturedProduct.setValue(product) }
        }

        let testProduct = Product(id: UUID(), name: "Test Product")
        output.onSave(testProduct)

        await Task.yield()

        let captured = await capturedProduct.getValue()
        #expect(captured?.id == testProduct.id)
        #expect(captured?.name == testProduct.name)
    }

    actor ActorBox<T> {
        private var value: T

        init(_ initialValue: T) {
            value = initialValue
        }

        func setValue(_ newValue: T) {
            value = newValue
        }

        func getValue() -> T {
            value
        }
    }

    // MARK: - Product List Input Tests

    @Test("ProductListInput default initialization")
    func productListInputDefaultInitialization() {
        let input = ProductListInput()

        #expect(input.filterType == .all)
    }

    @Test("ProductListInput with all filter")
    func productListInputWithAllFilter() {
        let input = ProductListInput(filterType: .all)

        #expect(input.filterType == .all)
    }

    @Test("ProductListInput with favorites filter")
    func productListInputWithFavoritesFilter() {
        let input = ProductListInput(filterType: .favorites)

        #expect(input.filterType == .favorites)
    }

    // MARK: - Filter Type Tests

    @Test("ProductListFilterType case iterable")
    func productListFilterTypeCaseIterable() {
        let allCases = ProductListInput.FilterType.allCases

        #expect(allCases.contains(.all))
        #expect(allCases.contains(.favorites))
    }

    @Test("ProductListFilterType raw values", arguments: [
        (ProductListInput.FilterType.all, "all"),
        (ProductListInput.FilterType.favorites, "favorites")
    ])
    func productListFilterTypeRawValues(filterType: ProductListInput.FilterType, expectedRawValue: String) {
        #expect(filterType.rawValue == expectedRawValue)
    }

    // MARK: - Sendable Conformance Test

    @Test("Sendable conformance")
    func sendableConformance() {
        // Test that types conform to Sendable
        func testSendable(_: (some Sendable).Type) {}

        testSendable(Product.self)
        testSendable(ProductDetailInput.self)
        testSendable(ProductDetailOutput.self)
        testSendable(ProductEditInput.self)
        testSendable(ProductEditOutput.self)
        testSendable(ProductListInput.self)
        testSendable(ProductListOutput.self)
        testSendable(ProductListInput.FilterType.self)
    }
}
