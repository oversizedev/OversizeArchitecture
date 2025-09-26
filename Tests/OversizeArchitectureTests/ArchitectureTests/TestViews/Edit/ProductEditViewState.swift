//
// Copyright © 2025 Alexander Romanov
// ProductEditViewState.swift, created on 17.09.2025
//

@testable import OversizeArchitecture
import SwiftUI

@Observable
public final class ProductEditViewState: ViewStateProtocol {
    public var name: String = .init()

    public let mode: EditMode
    public let productId: UUID

    public init(input: ProductEdit.Input?) {
        if let id = input?.productId {
            mode = .edit
            productId = id
        } else {
            mode = .create
            productId = UUID()
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
