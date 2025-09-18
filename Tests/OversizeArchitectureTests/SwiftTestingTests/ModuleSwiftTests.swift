//
// Copyright © 2025 Alexander Romanov
// ModuleSwiftTests.swift, created on 18.09.2025
//

import Foundation
import Testing
@testable import OversizeArchitecture

@Suite("Module Tests")
struct ModuleSwiftTests {

    @Test("Module protocol conformance")
    func moduleProtocolConformance() {
        // Test that modules conform to ModuleProtocol
        func testModuleProtocol<T: ModuleProtocol>(_: T.Type) {}

        testModuleProtocol(ProductDetailModule.self)
        testModuleProtocol(ProductEditModule.self)
        testModuleProtocol(ProductListModule.self)
    }

    @Test("ProductDetailModule typealiases")
    func productDetailModuleTypealiases() {
        // Test that typealiases are correctly defined
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            return T.self == U.self
        }

        #expect(testTypealias(ProductDetailModule.Input.self, ProductDetailInput.self))
        #expect(testTypealias(ProductDetailModule.Output.self, ProductDetailOutput.self))
        #expect(testTypealias(ProductDetailModule.ViewState.self, ProductDetailViewState.self))
        #expect(testTypealias(ProductDetailModule.ViewModel.self, ProductDetailViewModel.self))
    }

    @Test("ProductEditModule typealiases")
    func productEditModuleTypealiases() {
        // Test that typealiases are correctly defined
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            return T.self == U.self
        }

        #expect(testTypealias(ProductEditModule.Input.self, ProductEditInput.self))
        #expect(testTypealias(ProductEditModule.Output.self, ProductEditOutput.self))
        #expect(testTypealias(ProductEditModule.ViewState.self, ProductEditViewState.self))
        #expect(testTypealias(ProductEditModule.ViewModel.self, ProductEditViewModel.self))
    }

    @Test("ProductListModule typealiases")
    func productListModuleTypealiases() {
        // Test that typealiases are correctly defined
        func testTypealias<T, U>(_: T.Type, _: U.Type) -> Bool {
            return T.self == U.self
        }

        #expect(testTypealias(ProductListModule.Input.self, ProductListInput.self))
        #expect(testTypealias(ProductListModule.Output.self, ProductListOutput.self))
        #expect(testTypealias(ProductListModule.ViewState.self, ProductListViewState.self))
        #expect(testTypealias(ProductListModule.ViewModel.self, ProductListViewModel.self))
    }
}