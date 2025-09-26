# OversizeArchitecture

Swift architectural package with macros for automatic MVVM code generation.

## Macros

### @ViewModel

Automatically generates ViewModelProtocol components:

```swift
@ViewModel(module: ProductList.self)
public actor ProductListViewModel: ViewModelProtocol {
    func onRefresh() {
        // refresh logic
    }

    func onFilterSelected(filter: FilterType) {
        // filter logic
    }
}
```

Generates:
- Typealiases for Input, Output, ViewState
- Properties: state, input, output
- Initializer
- handleAction method
- Action enum with cases based on methods with "on" prefix

### @View

Generates View components:

```swift
@View(module: ProductList.self)
public struct ProductListView: ViewProtocol {
    public var body: some View {
        VStack {
            Text(viewState.title)
            Button("Refresh") {
                reducer(.onRefresh)
            }
        }
    }
}
```

Generates:
- viewState property
- reducer property
- Initializer

### @Module

Generates Module typealiases:

```swift
@Module
public enum ProductList: ModuleProtocol {
}
```

Generates:
- typealias Input = ProductListInput
- typealias Output = ProductListOutput
- typealias ViewState = ProductListViewState
- typealias ViewModel = ProductListViewModel
- typealias ViewScene = ProductListView

## Module Structure

Each module consists of:

1. **Input** - input parameters
2. **Output** - callbacks
3. **ViewState** - UI state
4. **ViewModel** - business logic
5. **View** - UI component
6. **Module** - entry point

## Complete Module Example

```swift
// ProductListModule.swift
public struct ProductListInput: Sendable {
    public let filterType: FilterType
    // ...
}

public struct ProductListOutput: Sendable {
    public let onSelection: (Product) -> Void
    // ...
}

@Module
public enum ProductList: ModuleProtocol {
}

// ProductListViewState.swift
@Observable
public final class ProductListViewState: ViewStateProtocol {
    // UI state
}

// ProductListViewModel.swift
@ViewModel(module: ProductList.self)
public actor ProductListViewModel: ViewModelProtocol {
    func onRefresh() { }
    func onFilterSelected(filter: FilterType) { }
}

// ProductListView.swift
@View(module: ProductList.self)
public struct ProductListView: ViewProtocol {
    public var body: some View {
        // UI code
    }
}
```

## Requirements

- Swift 6.0+
- iOS 17.0+
- macOS 14.0+