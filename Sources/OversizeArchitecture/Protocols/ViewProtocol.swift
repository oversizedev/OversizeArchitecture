//
// Copyright © 2025 Alexander Romanov
// ViewProtocol.swift, created on 04.07.2025
//

import SwiftUI

public protocol ViewProtocol: View {
    associatedtype ViewState: ViewStateProtocol
    associatedtype ViewModel: ViewModelProtocol

    init(viewState: ViewState, reducer: Reducer<ViewModel>)
}
