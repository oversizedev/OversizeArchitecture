//
// Copyright © 2025 Alexander Romanov
// ViewProtocol.swift, created on 04.07.2025
//

import Foundation
import SwiftUI

public protocol ViewProtocol: View {
    associatedtype ViewState: ViewStateProtocol
    associatedtype ViewModel: ViewModelProtocol

    @MainActor
    init(viewState: ViewState, reducer: Reducer<ViewModel>)
}
