//
// Copyright © 2025 Alexander Romanov
// ProductDetailModule.swift, created on 17.09.2025
//

import Foundation
@testable import OversizeArchitecture

public enum ProductDetailModule: ModuleProtocol {
    public typealias Input = ProductDetailInput
    public typealias Output = ProductDetailOutput
    public typealias ViewState = ProductDetailViewState
    public typealias ViewModel = ProductDetailViewModel
    public typealias ViewScene = ProductDetailView
}
