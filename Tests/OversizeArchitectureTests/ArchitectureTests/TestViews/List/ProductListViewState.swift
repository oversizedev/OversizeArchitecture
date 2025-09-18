//
// Copyright © 2025 Alexander Romanov
// ProductListViewState.swift, created on 17.09.2025
//

import SwiftUI
@testable import OversizeArchitecture

@Observable
public final class ProductListViewState: ViewStateProtocol {

    public let filterType: ProductListInput.FilterType

    public var title: String {
        filterType.title
    }

    public init(input: ProductListInput?) {
        self.filterType = input?.filterType ?? .all
    }
}
