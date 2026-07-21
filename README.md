# OversizeArchitecture

Swift architectural package with macros for automatic MVVM code generation. Each feature is a self-contained module with a strict, compiler-enforced structure — Input, Output, ViewState, ViewModel, and View — wired together by three Swift macros.

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/oversizedev/OversizeArchitecture.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "OversizeArchitecture", package: "OversizeArchitecture")
        ]
    )
]
```

## Idiomatic Example

A notes app with two modules — `NoteList` and `NoteDetail` — composed together via `Output`.

### Model

```swift
struct Note: Identifiable, Sendable {
    let id: UUID
    var title: String
    var body: String
    var isArchived: Bool
}
```

---

### NoteList module

**NoteList.swift** — module namespace, input, and output

```swift
import Foundation
import OversizeArchitecture

public struct NoteListInput: Sendable {
    public let filter: Filter

    public enum Filter: Sendable {
        case all, archived
    }

    public init(filter: Filter = .all) {
        self.filter = filter
    }
}

public struct NoteListOutput: Sendable {
    public let onSelectNote: Callback<UUID>

    public init(onSelectNote: Callback<UUID>) {
        self.onSelectNote = onSelectNote
    }
}

@Module
public enum NoteList: ModuleProtocol {}
```

**NoteListViewState.swift**

```swift
import OversizeArchitecture
import Observation

@Observable
public final class NoteListViewState: ViewStateProtocol {
    public var notes: [Note] = []
    public var filter: NoteListInput.Filter

    public var filteredNotes: [Note] {
        switch filter {
        case .all:      notes.filter { !$0.isArchived }
        case .archived: notes.filter { $0.isArchived }
        }
    }

    public var title: String {
        switch filter {
        case .all:      "Notes"
        case .archived: "Archive"
        }
    }

    public init(input: NoteList.Input?) {
        filter = input?.filter ?? .all
    }
}
```

**NoteListViewModel.swift**

```swift
import OversizeArchitecture
import SwiftUI

@ViewModel(module: NoteList.self)
public actor NoteListViewModel: ViewModelProtocol {
    func onAppear() async {
        let loaded = await NoteService.shared.fetchNotes()
        await state.update { $0.notes = loaded }
    }

    func onSelectNote(id: UUID) {
        output?.onSelectNote(id)
    }

    func onToggleFilter(filter: NoteListInput.Filter) async {
        await state.update { $0.filter = filter }
    }
}
```

**NoteListView.swift**

```swift
import OversizeArchitecture
import SwiftUI

@View(module: NoteList.self)
public struct NoteListView: ViewProtocol {
    public var body: some View {
        NavigationStack {
            List(viewState.filteredNotes) { note in
                Button(note.title) {
                    reducer(.onSelectNote(id: note.id))
                }
            }
            .navigationTitle(viewState.title)
            .toolbar {
                Picker("Filter", selection: $viewState.filter) {
                    Text("Notes").tag(NoteListInput.Filter.all)
                    Text("Archive").tag(NoteListInput.Filter.archived)
                }
                .pickerStyle(.segmented)
            }
        }
        .task { reducer(.onAppear) }
    }
}

#Preview {
    NoteList.build(
        output: NoteListOutput(
            onSelectNote: Callback { id in print("Selected: \(id)") }
        )
    )
}
```

---

### NoteDetail module

**NoteDetail.swift**

```swift
import Foundation
import OversizeArchitecture

public struct NoteDetailInput: Sendable {
    public let noteId: UUID

    public init(noteId: UUID) {
        self.noteId = noteId
    }
}

public struct NoteDetailOutput: Sendable {
    public init() {}
}

@Module
public enum NoteDetail: ModuleProtocol {}
```

**NoteDetailViewState.swift**

```swift
import OversizeArchitecture
import Observation

@Observable
public final class NoteDetailViewState: ViewStateProtocol {
    public var title: String = "Note"
    public var body: String = ""

    public init(input: NoteDetail.Input?) {}
}
```

**NoteDetailViewModel.swift**

```swift
import OversizeArchitecture
import SwiftUI

@ViewModel(module: NoteDetail.self)
public actor NoteDetailViewModel: ViewModelProtocol {
    func onAppear() async {
        guard let noteId = input?.noteId,
              let note = await NoteService.shared.fetchNote(id: noteId)
        else { return }

        await state.update {
            $0.title = note.title
            $0.body = note.body
        }
    }
}
```

**NoteDetailView.swift**

```swift
import OversizeArchitecture
import SwiftUI

@View(module: NoteDetail.self)
public struct NoteDetailView: ViewProtocol {
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewState.title)
                    .font(.largeTitle.bold())
                Text(viewState.body)
            }
            .padding()
        }
        .task { reducer(.onAppear) }
    }
}

#Preview {
    NoteDetail.build(input: NoteDetailInput(noteId: UUID()))
}
```

---

### Composing modules

```swift
struct ContentView: View {
    @State private var selectedNoteId: UUID?

    var body: some View {
        NavigationSplitView {
            NoteList.build(
                input: NoteListInput(),
                output: NoteListOutput(
                    onSelectNote: Callback { id in
                        Task { @MainActor in
                            selectedNoteId = id
                        }
                    }
                )
            )
        } detail: {
            if let id = selectedNoteId {
                NoteDetail.buildCached(
                    cacheKey: id.uuidString,
                    input: NoteDetailInput(noteId: id)
                )
            }
        }
    }
}
```

---

## Macros

### @Module

Declares the module namespace and generates five typealiases.

```swift
@Module
public enum NoteList: ModuleProtocol {}

// Generates:
// typealias Input     = NoteListInput
// typealias Output    = NoteListOutput
// typealias ViewState = NoteListViewState
// typealias ViewModel = NoteListViewModel
// typealias ViewScene = NoteListView
```

### @ViewModel

Generates `Action` enum, `handleAction()`, stored properties, and initializer.

```swift
@ViewModel(module: NoteList.self)
public actor NoteListViewModel: ViewModelProtocol {
    func onAppear() async { ... }
    func onSelectNote(id: UUID) { ... }
    func onToggleFilter(filter: NoteListInput.Filter) async { ... }
}

// Generates:
// enum Action { case onAppear, onSelectNote(id: UUID), onToggleFilter(filter: ...) }
// func handleAction(_ action: Action) async { ... }
// var state: NoteListViewState
// var input: NoteListInput?
// var output: NoteListOutput?
// init(state:input:output:)
```

### @View

Generates `viewState`, `reducer`, and initializer.

```swift
@View(module: NoteList.self)
public struct NoteListView: ViewProtocol {
    public var body: some View { ... }
}

// Generates:
// @Bindable var viewState: NoteListViewState
// let reducer: Reducer<NoteListViewModel>
// @MainActor init(viewState:reducer:)
```

---

## Building Modules

```swift
// Fresh instance every time
NoteList.build()
NoteList.build(input: NoteListInput(filter: .archived))
NoteList.build(input: NoteListInput(), output: NoteListOutput(onSelectNote: ...))

// Cached ViewState — survives navigation pop/push
NoteDetail.buildCached(cacheKey: note.id.uuidString, input: NoteDetailInput(noteId: note.id))
```

`buildCached` reuses the existing `ViewState` for the given key, so scroll position and loaded data are preserved when navigating back and forth.

---

## Requirements

- Swift 6.0+
- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- watchOS 10.0+
