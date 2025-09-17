//
// Copyright © 2025 Alexander Romanov
// ProductListModule.swift, created on 17.09.2025
//

import Foundation

public enum ProductListModule: ModuleProtocol {
    public typealias Input = ProductListInput
    public typealias Output = ProductListOutput
    public typealias ViewState = ProductListViewState
    public typealias ViewModel = ProductListViewModel
    public typealias ViewScene = ProductListView
}
