//
// Copyright © 2025 Alexander Romanov
// ProductListViewState.swift, created on 17.09.2025
//

@testable import OversizeArchitecture
import SwiftUI

@Observable
public final class ProductListViewState: ViewStateProtocol {
    public let filterType: ProductListInput.FilterType

    public var title: String {
        filterType.title
    }

    public init(input: ProductList.Input?) {
        filterType = input?.filterType ?? .all
    }
}
