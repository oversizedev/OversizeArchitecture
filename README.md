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

## Sending Actions

`Reducer` is `@MainActor`. For an `actor` ViewModel or one isolated to a global actor such as `@MainActor`, actions enter the ViewModel in the order they are sent. A long action does not block the next one: once it suspends at an `await`, the following actions run, as usual for actor reentrancy. A nonisolated `Sendable` class runs `handleAction` on the concurrent executor, so its actions have no ordering guarantee; use an actor when order matters.

```swift
reducer(.onTapSave)                      // fire and forget, returns the Task
.task { await reducer.send(.onAppear) }  // waits; cancelled together with the view's task
reducer.cancelAll()                      // explicit cancellation of running actions
```

Running actions are never cancelled automatically when the module goes away.

---

## Testing

Add the `OversizeArchitectureTesting` product to your test target. `ModuleTestHost` builds the module's ViewState, ViewModel and Reducer without a View, so screens can be tested headless with `swift test`.

```swift
import OversizeArchitectureTesting
import Testing

@MainActor
struct NoteListTests {
    @Test
    func loadsNotes() async {
        let host = ModuleTestHost<NoteList>(input: NoteListInput(filter: .archived))

        await host.send(.onAppear)

        #expect(host.state.notes.isEmpty == false)
    }
}
```

`send` runs the actions one after another and waits for each of them to finish.

---

## Introspection

Introspection lets tests and tools drive a screen through data: send an action as JSON, then read the ViewState as JSON.

### Codable actions

Opt in on the ViewModel:

```swift
@ViewModel(module: NoteList.self, introspectable: true)
public actor NoteListViewModel: ViewModelProtocol {
    func onAppear() async { ... }
    func onSelect(_ id: UUID) async { ... }
    func onRename(id: UUID, title: String) async { ... }
}
```

The generated `Action` then conforms to `IntrospectableAction` (`Codable`). It uses Swift's synthesized enum coding:

```json
{"onAppear":{}}
{"onSelect":{"_0":"6F9619FF-8B86-D011-B42D-00C04FC964FF"}}
{"onRename":{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Groceries"}}
```

Unlabeled parameters use `_<position>` keys. Every parameter type must be `Codable`, otherwise the ViewModel does not compile. Keep `introspectable` off for view models that take callbacks or other non-Codable values.

`Action.descriptors` lists the available actions with their parameter labels, coding keys and types as written in source:

```swift
NoteList.ViewModel.Action.descriptors
// [ActionDescriptor(name: "onAppear", parameters: []),
//  ActionDescriptor(name: "onSelect", parameters: [.init(label: nil, codingKey: "_0", type: "UUID")]), ...]
```

The type strings are documentation, not a JSON schema.

### State snapshots

Conform the ViewState to `IntrospectableViewState` to get `snapshot() -> JSONValue` and `snapshotJSON() -> Data` (sorted keys):

```swift
@Observable
public final class NoteListViewState: IntrospectableViewState { ... }
```

The default snapshot reflects stored properties with `Mirror`:
- Observation's `_` prefix and registrar are removed.
- Computed properties are not included, private stored properties are.
- `Date` becomes an ISO 8601 string, `URL`, `UUID` and `Decimal` become strings.
- Enums become `"case"` or `{"case": payload}`.
- Reference cycles become `"<cycle>"` and nesting deeper than 16 levels becomes `"<truncated>"`.

Implement `snapshot()` yourself when you need a stable or redacted shape.

### Sending JSON

```swift
try await reducer.send(json: #"{"onSelect":{"_0":"6F9619FF-8B86-D011-B42D-00C04FC964FF"}}"#)

let host = ModuleTestHost<NoteList>()
try await host.send(json: #"{"onAppear":{}}"#)
#expect(host.snapshot() == ["notes": [], "isLoading": false])
```

Invalid JSON throws a `DecodingError` before anything is sent.

---

## Module Registry and Debug Server

An agent or a script on your Mac can read the state of screens in a running app and send them actions: the app keeps a registry of modules on screen, and the `OversizeArchitectureDebug` product serves it on a local socket. Both work only in Debug builds. In Release the API still compiles but does nothing.

### Registry

`ModuleRegistry` is a `@MainActor` list of the modules currently on screen. A module built with `build` or `buildCached` registers in `onAppear` and unregisters in `onDisappear`, but only when a registry is in the environment:

```swift
let registry = ModuleRegistry()

RootView()
    .moduleRegistry(registry)

registry.modules              // [RegisteredModule]: id, name, capabilities
try registry.snapshot(of: id) // JSONValue, needs IntrospectableViewState
try await registry.send(json: Data(#"{"onAppear":{}}"#.utf8), to: id)
```

Each entry has a per-instance `id` and the module name (`"NoteList"`), plus three capabilities:
- `snapshot()` when the ViewState conforms to `IntrospectableViewState`;
- `send(json:)` when the `Action` is `Decodable`, for example a `@ViewModel(introspectable: true)` one. It waits until the ViewModel returns from the action;
- `actionDescriptors` when the `Action` is `IntrospectableAction`.

The registry does not keep a module alive. A screen covered by a pushed screen disappears from the registry until it is shown again.

In tests, register a `ModuleTestHost` without a View:

```swift
let registry = ModuleRegistry()
let host = ModuleTestHost<NoteList>()
host.register(in: registry)
try await registry.send(json: Data(#"{"onAppear":{}}"#.utf8), to: host.id)
```

### Debug server

Add the `OversizeArchitectureDebug` product to the app target and start the server at the root:

```swift
import OversizeArchitectureDebug

WindowGroup {
    RootView()
        .moduleDebugServer()
}
```

The modifier creates a registry, puts it into the environment and listens on `127.0.0.1:47800` while the root view is alive. The iOS Simulator shares the Mac's loopback, so tools on the Mac reach the app directly. A sandboxed macOS app needs the `com.apple.security.network.server` entitlement. To use a different port or require a token, pass a configuration: `.moduleDebugServer(DebugServer.Configuration(port: 47801, token: "secret"))`. Port `0` picks a free port and logs it. For full control, create a `DebugServer(registry:configuration:)` yourself and call `start()` and `stop()`.

### Protocol

The server speaks JSON-RPC 2.0, one compact JSON message per line (UTF-8, `\n`, up to 1 MB):

| Method | Params | Result |
| --- | --- | --- |
| `app.hello` | `{"token"?}` | bundle id, process, `protocolVersion`, methods |
| `modules.list` | — | `{"modules":[{"id","name","stateIntrospectable","acceptsActions","describesActions"}]}` |
| `state.get` | `{"module"}` | `{"module","state"}` |
| `actions.list` | `{"module"}` | `{"module","actions":[ActionDescriptor]}` |
| `action.send` | `{"module","action"}` | `{"module","state"}`, the state after the action |

`module` is an instance id or a module name. A name resolves to the most recently shown module with that name. Errors use the standard JSON-RPC codes plus `-32001` module not found, `-32002` module gone, `-32003` capability not supported, `-32004` action does not decode and `-32005` unauthorized. With a token, a connection must call `app.hello` with it first.

```
→ {"jsonrpc":"2.0","id":1,"method":"action.send","params":{"module":"NoteList","action":{"onAppear":{}}}}
← {"id":1,"jsonrpc":"2.0","result":{"module":"6F96…","state":{"isLoading":false,"notes":[]}}}
```

### CLI and MCP

The package includes a macOS command line tool:

```bash
swift run oversize-debug list
swift run oversize-debug state NoteList
swift run oversize-debug actions NoteList
swift run oversize-debug send NoteList '{"onSelect":{"_0":"6F9619FF-8B86-D011-B42D-00C04FC964FF"}}'
```

`--host`, `--port` and `--token` (or `OVERSIZE_DEBUG_HOST`, `OVERSIZE_DEBUG_PORT`, `OVERSIZE_DEBUG_TOKEN`) choose the app.

`oversize-debug mcp` runs an MCP server over stdio with the tools `app_info`, `list_modules`, `get_state`, `list_actions` and `send_action`. Register it with an agent, for example in Claude Code:

```bash
swift build -c release --product oversize-debug
claude mcp add oversize-debug -- /path/to/OversizeArchitecture/.build/release/oversize-debug mcp
```

The MCP server connects to the app when a tool is called and reconnects after the app restarts.

---

## Requirements

- Swift 6.0+
- iOS 17.0+
- macOS 14.0+
- tvOS 17.0+
- watchOS 10.0+
