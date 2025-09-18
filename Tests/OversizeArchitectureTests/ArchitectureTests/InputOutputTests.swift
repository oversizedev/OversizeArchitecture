//
// Copyright © 2025 Alexander Romanov
// InputOutputTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture

actor InputOutputProductBox {
    private var product: Product?

    func setProduct(_ product: Product?) {
        self.product = product
    }

    func getProduct() -> Product? {
        return product
    }
}

final class InputOutputTests: XCTestCase {

    // MARK: - ProductListInput Tests

    func testProductListInputWithAllFilter() {
        let input = ProductListInput(filterType: .all)

        XCTAssertEqual(input.filterType, .all)
        XCTAssertEqual(input.filterType.title, "All Products")
    }

    func testProductListInputWithFavoritesFilter() {
        let input = ProductListInput(filterType: .favorites)

        XCTAssertEqual(input.filterType, .favorites)
        XCTAssertEqual(input.filterType.title, "Favorites")
    }

    func testProductListInputDefaultInitialization() {
        let input = ProductListInput()

        XCTAssertEqual(input.filterType, .all)
        XCTAssertEqual(input.filterType.title, "All Products")
    }

    func testProductListFilterTypeCaseIterable() {
        let allCases = ProductListInput.FilterType.allCases

        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.favorites))
    }

    func testProductListFilterTypeRawValue() {
        XCTAssertEqual(ProductListInput.FilterType.all.rawValue, "all")
        XCTAssertEqual(ProductListInput.FilterType.favorites.rawValue, "favorites")
    }

    func testProductListOutputInitialization() {
        let output = ProductListOutput()
        XCTAssertNotNil(output)
    }

    // MARK: - ProductDetailInput Tests

    func testProductDetailInputWithId() {
        let id = UUID()
        let input = ProductDetailInput(id: id)

        XCTAssertEqual(input.productId, id)

        switch input.source {
        case .id(let sourceId):
            XCTAssertEqual(sourceId, id)
        case .product:
            XCTFail("Expected .id source")
        }
    }

    func testProductDetailInputWithProduct() {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductDetailInput(product: product)

        XCTAssertEqual(input.productId, product.id)

        switch input.source {
        case .id:
            XCTFail("Expected .product source")
        case .product(let sourceProduct):
            XCTAssertEqual(sourceProduct.id, product.id)
            XCTAssertEqual(sourceProduct.name, product.name)
        }
    }

    func testProductDetailOutputInitialization() {
        let output = ProductDetailOutput()
        XCTAssertNotNil(output)
    }

    // MARK: - ProductEditInput Tests

    func testProductEditInputWithId() {
        let id = UUID()
        let input = ProductEditInput(id: id)

        XCTAssertEqual(input.productId, id)

        switch input.source {
        case .id(let sourceId):
            XCTAssertEqual(sourceId, id)
        case .product:
            XCTFail("Expected .id source")
        case .none:
            XCTFail("Expected non-nil source")
        }
    }

    func testProductEditInputWithProduct() {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)

        XCTAssertEqual(input.productId, product.id)

        switch input.source {
        case .id:
            XCTFail("Expected .product source")
        case .product(let sourceProduct):
            XCTAssertEqual(sourceProduct.id, product.id)
            XCTAssertEqual(sourceProduct.name, product.name)
        case .none:
            XCTFail("Expected non-nil source")
        }
    }

    func testProductEditInputEmpty() {
        let input = ProductEditInput()

        XCTAssertNil(input.productId)
        XCTAssertNil(input.source)
    }

    func testProductEditOutput() async {
        let savedProduct = InputOutputProductBox()

        let output = ProductEditOutput { product in
            Task { await savedProduct.setProduct(product) }
        }

        let testProduct = Product(id: UUID(), name: "Test Product")
        output.onSave(testProduct)

        // Give time for the async task to complete
        try? await Task.sleep(for: .milliseconds(10))

        let result = await savedProduct.getProduct()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, testProduct.id)
        XCTAssertEqual(result?.name, testProduct.name)
    }

    // MARK: - Sendable Tests

    func testSendableConformance() {
        Task {
            let listInput = ProductListInput(filterType: .all)
            let listOutput = ProductListOutput()
            let detailInput = ProductDetailInput(id: UUID())
            let detailOutput = ProductDetailOutput()
            let editInput = ProductEditInput()
            let editOutput = ProductEditOutput { _ in }

            XCTAssertNotNil(listInput)
            XCTAssertNotNil(listOutput)
            XCTAssertNotNil(detailInput)
            XCTAssertNotNil(detailOutput)
            XCTAssertNotNil(editInput)
            XCTAssertNotNil(editOutput)
        }
    }
}