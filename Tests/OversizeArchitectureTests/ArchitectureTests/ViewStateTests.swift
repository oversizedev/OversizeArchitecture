//
// Copyright © 2025 Alexander Romanov
// ViewStateTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture

final class ViewStateTests: XCTestCase {

    @MainActor
    func testProductListViewStateWithAllFilter() {
        let input = ProductListInput(filterType: .all)
        let viewState = ProductListViewState(input: input)

        XCTAssertEqual(viewState.filterType, .all)
        XCTAssertEqual(viewState.title, "All Products")
    }

    @MainActor
    func testProductListViewStateWithFavoritesFilter() {
        let input = ProductListInput(filterType: .favorites)
        let viewState = ProductListViewState(input: input)

        XCTAssertEqual(viewState.filterType, .favorites)
        XCTAssertEqual(viewState.title, "Favorites")
    }

    @MainActor
    func testProductListViewStateWithNilInput() {
        let viewState = ProductListViewState(input: nil)

        XCTAssertEqual(viewState.filterType, .all)
        XCTAssertEqual(viewState.title, "All Products")
    }

    @MainActor
    func testProductDetailViewStateWithInput() {
        let productId = UUID()
        let input = ProductDetailInput(id: productId)
        let viewState = ProductDetailViewState(input: input)

        XCTAssertEqual(viewState.id, productId)
        XCTAssertEqual(viewState.name, "Product")
    }

    @MainActor
    func testProductDetailViewStateWithNilInput() {
        let viewState = ProductDetailViewState(input: nil)

        XCTAssertNotNil(viewState.id)
        XCTAssertEqual(viewState.name, "Product")
    }

    @MainActor
    func testProductEditViewStateCreateMode() {
        let input = ProductEditInput()
        let viewState = ProductEditViewState(input: input)

        XCTAssertEqual(viewState.mode, .create)
        XCTAssertEqual(viewState.mode.title, "Create Product")
        XCTAssertNotNil(viewState.productId)
        XCTAssertEqual(viewState.name, "")
    }

    @MainActor
    func testProductEditViewStateEditMode() {
        let productId = UUID()
        let input = ProductEditInput(id: productId)
        let viewState = ProductEditViewState(input: input)

        XCTAssertEqual(viewState.mode, .edit)
        XCTAssertEqual(viewState.mode.title, "Edit Product")
        XCTAssertEqual(viewState.productId, productId)
        XCTAssertEqual(viewState.name, "")
    }

    @MainActor
    func testProductEditViewStateWithProduct() {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)
        let viewState = ProductEditViewState(input: input)

        XCTAssertEqual(viewState.mode, .edit)
        XCTAssertEqual(viewState.productId, product.id)
    }

    @MainActor
    func testProductEditViewStateWithNilInput() {
        let viewState = ProductEditViewState(input: nil)

        XCTAssertEqual(viewState.mode, .create)
        XCTAssertEqual(viewState.mode.title, "Create Product")
        XCTAssertNotNil(viewState.productId)
    }

    func testViewStateProtocolConformance() {
        func testViewStateProtocol<T: ViewStateProtocol>(_ viewState: T.Type) {}

        testViewStateProtocol(ProductListViewState.self)
        testViewStateProtocol(ProductDetailViewState.self)
        testViewStateProtocol(ProductEditViewState.self)
    }
}