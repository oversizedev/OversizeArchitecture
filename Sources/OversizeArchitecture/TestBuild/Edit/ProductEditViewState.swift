//
// Copyright © 2025 Alexander Romanov
// ProductEditViewState.swift, created on 17.09.2025
//

import SwiftUI

@Observable
public final class ProductEditViewState: ViewStateProtocol {

    public var name: String = .init()

    public let mode: EditMode
    public let productId: UUID

    public init(input: ProductEditModule.Input?) {
        if let id = input?.productId {
            self.mode = .edit
            self.productId = id
        } else {
            self.mode = .create
            self.productId = UUID()
        }
    }

    public enum EditMode {
        case create, edit
        
        var title: String {
            switch self {
            case .create:
                "Create Product"
            case .edit:
                "Edit Product"
            }
        }
    }
}
