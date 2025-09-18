//
// Copyright © 2025 Alexander Romanov
// ProductTests.swift, created on 18.09.2025
//

import XCTest
@testable import OversizeArchitecture

final class ProductTests: XCTestCase {

    func testProductInitialization() {
        let id = UUID()
        let name = "Test Product"

        let product = Product(id: id, name: name)

        XCTAssertEqual(product.id, id)
        XCTAssertEqual(product.name, name)
    }

    func testProductSendable() {
        let product = Product(id: UUID(), name: "Test")

        Task {
            let productCopy = product
            XCTAssertEqual(productCopy.name, "Test")
        }
    }

    func testProductEquality() {
        let id = UUID()
        let product1 = Product(id: id, name: "Test Product")
        let product2 = Product(id: id, name: "Test Product")
        let product3 = Product(id: UUID(), name: "Test Product")

        XCTAssertEqual(product1.id, product2.id)
        XCTAssertEqual(product1.name, product2.name)
        XCTAssertNotEqual(product1.id, product3.id)
    }
}