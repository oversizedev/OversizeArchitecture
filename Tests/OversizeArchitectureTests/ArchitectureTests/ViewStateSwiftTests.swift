//
// Copyright © 2025 Alexander Romanov
// ViewStateSwiftTests.swift, created on 18.09.2025
//

import Foundation
import Testing
@testable import OversizeArchitecture

@Suite("View State Tests")
struct ViewStateSwiftTests {

    // MARK: - Product Detail View State Tests

    @Test("ProductDetailViewState with input")
    func productDetailViewStateWithInput() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductDetailInput(product: product)

        let state = await MainActor.run {
            ProductDetailViewState(input: input)
        }

        await MainActor.run {
            #expect(state.id == product.id)
            #expect(state.name == "Product")
        }
    }

    @Test("ProductDetailViewState with nil input")
    func productDetailViewStateWithNilInput() async {
        let state = await MainActor.run {
            ProductDetailViewState(input: nil)
        }

        await MainActor.run {
            #expect(state.name == "Product")
        }
    }

    // MARK: - Product Edit View State Tests

    @Test("ProductEditViewState create mode")
    func productEditViewStateCreateMode() async {
        let input = ProductEditInput()

        let state = await MainActor.run {
            ProductEditViewState(input: input)
        }

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.create)
            #expect(state.name == "")
        }
    }

    @Test("ProductEditViewState edit mode")
    func productEditViewStateEditMode() async {
        let productId = UUID()
        let input = ProductEditInput(id: productId)

        let state = await MainActor.run {
            ProductEditViewState(input: input)
        }

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.edit)
            #expect(state.productId == productId)
        }
    }

    @Test("ProductEditViewState with nil input")
    func productEditViewStateWithNilInput() async {
        let state = await MainActor.run {
            ProductEditViewState(input: nil)
        }

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.create)
            #expect(state.name == "")
        }
    }

    @Test("ProductEditViewState with product")
    func productEditViewStateWithProduct() async {
        let product = Product(id: UUID(), name: "Test Product")
        let input = ProductEditInput(product: product)

        let state = await MainActor.run {
            ProductEditViewState(input: input)
        }

        await MainActor.run {
            #expect(state.mode == ProductEditViewState.EditMode.edit)
            #expect(state.productId == product.id)
        }
    }

    // MARK: - Product List View State Tests

    @Test("ProductListViewState with all filter")
    func productListViewStateWithAllFilter() async {
        let input = ProductListInput(filterType: .all)

        let state = await MainActor.run {
            ProductListViewState(input: input)
        }

        await MainActor.run {
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    @Test("ProductListViewState with favorites filter")
    func productListViewStateWithFavoritesFilter() async {
        let input = ProductListInput(filterType: .favorites)

        let state = await MainActor.run {
            ProductListViewState(input: input)
        }

        await MainActor.run {
            #expect(state.filterType == .favorites)
            #expect(state.title == "Favorites")
        }
    }

    @Test("ProductListViewState with nil input")
    func productListViewStateWithNilInput() async {
        let state = await MainActor.run {
            ProductListViewState(input: nil)
        }

        await MainActor.run {
            #expect(state.filterType == .all)
            #expect(state.title == "All Products")
        }
    }

    // MARK: - ViewState Protocol Tests

    @Test("ViewState protocol conformance")
    func viewStateProtocolConformance() {
        func testViewStateProtocol<T: ViewStateProtocol>(_: T.Type) {}

        testViewStateProtocol(ProductDetailViewState.self)
        testViewStateProtocol(ProductEditViewState.self)
        testViewStateProtocol(ProductListViewState.self)
    }
}
