//
// Copyright © 2025 Alexander Romanov
// ModuleSwiftTests.swift, created on 18.09.2025
//

import Foundation
@testable import OversizeArchitecture
import Testing

@Suite("Module Tests")
struct ModuleSwiftTests {
    @Test("Module protocol conformance")
    func moduleProtocolConformance() {
        func testModuleProtocol(_: (some ModuleProtocol).Type) {}

        testModuleProtocol(ProductDetail.self)
        testModuleProtocol(ProductEdit.self)
        testModuleProtocol(ProductList.self)
    }

    @Test("ProductDetailModule typealiases")
    func productDetailModuleTypealiases() {
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            T.self == U.self
        }

        #expect(testTypealias(ProductDetail.Input.self, ProductDetailInput.self))
        #expect(testTypealias(ProductDetail.Output.self, ProductDetailOutput.self))
        #expect(testTypealias(ProductDetail.ViewState.self, ProductDetailViewState.self))
        #expect(testTypealias(ProductDetail.ViewModel.self, ProductDetailViewModel.self))
    }

    @Test("ProductEditModule typealiases")
    func productEditModuleTypealiases() {
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            T.self == U.self
        }

        #expect(testTypealias(ProductEdit.Input.self, ProductEditInput.self))
        #expect(testTypealias(ProductEdit.Output.self, ProductEditOutput.self))
        #expect(testTypealias(ProductEdit.ViewState.self, ProductEditViewState.self))
        #expect(testTypealias(ProductEdit.ViewModel.self, ProductEditViewModel.self))
    }

    @Test("ProductListModule typealiases")
    func productListModuleTypealiases() {
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            T.self == U.self
        }

        #expect(testTypealias(ProductList.Input.self, ProductListInput.self))
        #expect(testTypealias(ProductList.Output.self, ProductListOutput.self))
        #expect(testTypealias(ProductList.ViewState.self, ProductListViewState.self))
        #expect(testTypealias(ProductList.ViewModel.self, ProductListViewModel.self))
    }
}
