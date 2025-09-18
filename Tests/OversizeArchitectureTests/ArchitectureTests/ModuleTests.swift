//
// Copyright © 2025 Alexander Romanov
// ModuleTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture

final class ModuleTests: XCTestCase {

    func testProductListModuleTypealiases() {
        XCTAssertTrue(ProductListModule.Input.self == ProductListInput.self)
        XCTAssertTrue(ProductListModule.Output.self == ProductListOutput.self)
        XCTAssertTrue(ProductListModule.ViewState.self == ProductListViewState.self)
        XCTAssertTrue(ProductListModule.ViewModel.self == ProductListViewModel.self)
        XCTAssertTrue(ProductListModule.ViewScene.self == ProductListView.self)
    }

    func testProductDetailModuleTypealiases() {
        XCTAssertTrue(ProductDetailModule.Input.self == ProductDetailInput.self)
        XCTAssertTrue(ProductDetailModule.Output.self == ProductDetailOutput.self)
        XCTAssertTrue(ProductDetailModule.ViewState.self == ProductDetailViewState.self)
        XCTAssertTrue(ProductDetailModule.ViewModel.self == ProductDetailViewModel.self)
        XCTAssertTrue(ProductDetailModule.ViewScene.self == ProductDetailView.self)
    }

    func testProductEditModuleTypealiases() {
        XCTAssertTrue(ProductEditModule.Input.self == ProductEditInput.self)
        XCTAssertTrue(ProductEditModule.Output.self == ProductEditOutput.self)
        XCTAssertTrue(ProductEditModule.ViewState.self == ProductEditViewState.self)
        XCTAssertTrue(ProductEditModule.ViewModel.self == ProductEditViewModel.self)
        XCTAssertTrue(ProductEditModule.ViewScene.self == ProductEditView.self)
    }

    func testModuleProtocolConformance() {
        func testModuleProtocol<T: ModuleProtocol>(_ module: T.Type) {}

        testModuleProtocol(ProductListModule.self)
        testModuleProtocol(ProductDetailModule.self)
        testModuleProtocol(ProductEditModule.self)
    }
}