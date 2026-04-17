# Examples

Explore real-world examples that demonstrate the Bloc pattern in action.

## Overview

This guide walks through the example implementations included in the project, progressing from simple to more complex patterns.

## Counter Example

The Counter example demonstrates the fundamentals of the Bloc pattern with a simple integer state.

### What You'll Learn

- Basic Bloc setup with primitive state types
- Registering event handlers with `on(_:handler:)`
- Direct state access in SwiftUI views
- Sending events from UI interactions

### File Structure

```
Counter/
├── Blocs/
│   ├── CounterBloc.swift      # Business logic
│   └── CounterEvent.swift     # Event definitions
└── CounterView.swift          # SwiftUI view
```

### Events

The counter has three simple events:

```swift
enum CounterEvent: BlocEvent {
    case increment
    case decrement
    case reset
}
```

### Bloc Implementation

The `CounterBloc` uses `Int` as its state type—perfect for simple numeric values:

```swift
@MainActor
class CounterBloc: Bloc<Int, CounterEvent> {
    enum Consts {
        static let initialState: Int = 0
    }
    
    override init(initialState: Int = Consts.initialState) {
        super.init(initialState: initialState)
        
        self.on(.increment) { [weak self] event, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
        
        self.on(.decrement) { [weak self] event, emit in
            guard let self else { return }
            emit(self.state - 1)
        }
        
        self.on(.reset) { event, emit in
            emit(Consts.initialState)
        }
    }
}
```

**Key Points:**

1. **Default initial state**: The `initialState` parameter has a default value, making initialization simpler
2. **Constants enum**: Using `Consts` keeps magic numbers organized
3. **Weak self capture**: Prevents retain cycles in closures that access `self`
4. **Simple handlers**: Each event has a focused, single-purpose handler

### View Implementation

The view demonstrates the clean API enabled by `@Observable`:

```swift
struct CounterView: View {
    let counterBloc = BlocRegistry.resolve(CounterBloc.self)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \(counterBloc.state)")
                .font(.largeTitle)
                .bold()
            
            HStack(spacing: 50) {
                Button(action: {
                    counterBloc.send(.decrement)
                }) {
                    Image(systemName: "minus.circle")
                        .font(.largeTitle)
                }
                
                Button(action: {
                    counterBloc.send(.increment)
                }) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                }
            }
            
            Button(action: {
                counterBloc.send(.reset)
            }) {
                Text("Reset Counter")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Counter Sample")
    }
}
```

**Key Points:**

1. **Direct resolution**: `BlocRegistry.resolve(CounterBloc.self)` gets the Bloc instance
2. **No `@State` needed**: The view reads `counterBloc.state` directly
3. **Automatic updates**: SwiftUI re-renders when state changes
4. **Clean event sending**: `counterBloc.send(.increment)` is intuitive and type-safe

---

## Formula One Example

The Formula One example demonstrates advanced patterns including async operations, complex state, and loading indicators.

### What You'll Learn

- Using enums for complex, mutually-exclusive states
- Handling async network requests
- Using `mapEventToState` for events with associated values
- Pattern matching on state in SwiftUI views

### File Structure

```
FormulaOne/
├── Blocs/
│   ├── FormulaOneBloc.swift   # Business logic with async
│   ├── FormulaOneEvent.swift  # Event definitions
│   └── FormulaOneState.swift  # Complex state enum
├── Models/
│   ├── Driver.swift           # Data models
│   └── FormulaOneError.swift  # Error type
├── FormulaOneNetworkService.swift  # API service
└── FormulaOneView.swift       # SwiftUI view
```

### State Design

Instead of a struct, this example uses an **enum** for mutually exclusive states:

```swift
enum FormulaOneState: Equatable {
    case initial
    case loading
    case loaded([DriverChampionship])
    case error(FormulaOneError)
}
```

This pattern is excellent when your UI has distinct "modes" that don't overlap:

| State | UI |
|-------|-----|
| `.initial` | Show "Load" button |
| `.loading` | Show progress indicator |
| `.loaded([...])` | Show driver list |
| `.error(...)` | Show error message |

### Events

Two events drive the feature:

```swift
enum FormulaOneEvent: BlocEvent {
    case clear           // Reset to initial state
    case loadChampionship  // Fetch data from API
}
```

### Bloc Implementation

The `FormulaOneBloc` demonstrates async operations:

```swift
@MainActor
class FormulaOneBloc: Bloc<FormulaOneState, FormulaOneEvent> {
    
    override init(initialState: FormulaOneState = .initial) {
        super.init(initialState: initialState)
        
        // Simple event: use on(_:handler:)
        self.on(.clear) { event, emit in
            emit(.initial)
        }
    }
    
    // Complex events: use mapEventToState
    override func mapEventToState(
        event: FormulaOneEvent, 
        emit: @escaping Emitter
    ) {
        if case .loadChampionship = event {
            emit(.loading)  // Show loading state immediately
            Task {
                await loadChampionship()
            }
        }
    }
    
    fileprivate func loadChampionship() async {
        do {
            let networkService = FormulaOneNetworkService()
            let drivers = try await networkService.fetchDriversChampionship()
            emit(.loaded(drivers))  // Success: show data
        } catch {
            emit(.error(FormulaOneError()))  // Failure: show error
        }
    }
}
```

**Key Points:**

1. **Immediate feedback**: Emit `.loading` before starting async work
2. **Task for async**: Use `Task { }` to bridge sync handlers to async code
3. **Call emit directly**: From async contexts, call `self.emit(...)` directly
4. **Error handling**: Catch errors and emit error states

### View Implementation

The view uses `switch` to render different states:

```swift
struct FormulaOneView: View {
    let formulaOneBloc = BlocRegistry.resolve(FormulaOneBloc.self)
    
    var body: some View {
        VStack(spacing: 20) {
            // Conditional content based on state
            if formulaOneBloc.state == .initial {
                Text("This only appears in the initial state")
                    .font(.largeTitle)
                    .bold()
            }
            
            // Switch on all state cases
            switch formulaOneBloc.state {
            case .initial:
                Button(action: {
                    formulaOneBloc.send(.loadChampionship)
                }) {
                    Text("Tap to load the Formula 1 Driver's Championship")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
            case .loading:
                ProgressView("🏎️ Loading drivers championship...")
                    .progressViewStyle(CircularProgressViewStyle())
                
            case .loaded(let drivers):
                buildDriversList(drivers: drivers)
                
            case .error(let error):
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Driver's Championship")
    }
    
    @ViewBuilder
    func buildDriversList(drivers: [DriverChampionship]) -> some View {
        List(drivers) { driver in
            HStack {
                Text("#\(driver.driver.number)")
                    .font(.system(.title2, design: .monospaced))
                    .bold()
                
                VStack(alignment: .leading) {
                    Text("\(driver.driver.name) \(driver.driver.surname)")
                        .font(.headline)
                    Text(driver.team.teamName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Points: \(driver.points)")
                    .font(.headline)
                    .foregroundColor(.red)
            }
        }
        .toolbar {
            Button(action: {
                formulaOneBloc.send(.clear)
            }) {
                Text("🗑️")
            }
        }
    }
}
```

**Key Points:**

1. **State-driven UI**: The entire UI is determined by the current state
2. **Pattern matching**: `switch` ensures all states are handled
3. **Associated values**: Extract data from states like `.loaded(let drivers)`
4. **Toolbar actions**: Send events from anywhere in the view

---

## Comparison: Simple vs Complex State

| Aspect | Counter | Formula One |
|--------|---------|-------------|
| State type | `Int` (primitive) | `enum` (complex) |
| Event handling | `on(_:handler:)` only | Both `on` and `mapEventToState` |
| Async operations | None | Network requests |
| UI pattern | Direct value display | State-based switching |
| Error handling | Not needed | Error state case |

---

## Best Practices from Examples

### 1. Choose the Right State Type

- **Primitives** (`Int`, `String`, `Bool`): Great for simple values
- **Structs**: Best for related properties that change together
- **Enums**: Perfect for mutually exclusive states (loading, loaded, error)

### 2. Handle Async Properly

```swift
// ✅ Good: Emit loading, then async work
on(.fetch) { [weak self] event, emit in
    guard let self else { return }
    emit(.loading)
    Task {
        let result = await self.fetchData()
        self.emit(.loaded(result))
    }
}

// ❌ Bad: No loading state, user sees nothing
on(.fetch) { [weak self] event, emit in
    guard let self else { return }
    Task {
        let result = await self.fetchData()
        emit(.loaded(result))  // emit may not work from Task context
    }
}
```

### 3. Keep Views Declarative

```swift
// ✅ Good: Switch on state
switch bloc.state {
case .loading: ProgressView()
case .loaded(let data): DataView(data: data)
case .error(let e): ErrorView(error: e)
}

// ❌ Bad: Imperative checks
if bloc.isLoading { ... }
if bloc.data != nil { ... }
if bloc.error != nil { ... }
```

### 4. Use Default Initial States

```swift
// ✅ Good: Convenient initialization
override init(initialState: FormulaOneState = .initial) {
    super.init(initialState: initialState)
}

// Usage: FormulaOneBloc()  // No argument needed
```

---

## Lorcana Example

The Lorcana example demonstrates advanced patterns including search with debouncing, infinite scroll pagination, and multi-screen navigation for a trading card game browser.

### What You'll Learn

- Debounced search that triggers after a minimum character count
- Infinite scroll pagination with page tracking
- Multi-screen navigation (list → detail → set detail)
- Dynamic theming based on data properties
- Async image loading with placeholders

### File Structure

```
Lorcana/
├── Blocs/
│   ├── LorcanaBloc.swift       # Business logic with pagination
│   ├── LorcanaEvent.swift      # Search/pagination events
│   └── LorcanaState.swift      # State with cards, pagination, loading
├── Models/
│   ├── LorcanaCard.swift       # Card model with ink colors
│   ├── LorcanaSet.swift        # Set model
│   └── LorcanaError.swift      # Custom error type
├── Services/
│   └── LorcanaNetworkService.swift  # API integration
├── LorcanaView.swift           # Main view with search + infinite scroll
├── LorcanaCardDetailView.swift # Card detail with set navigation
└── LorcanaSetDetailView.swift  # Set detail with card grid
```

### State Design

Unlike the enum-based states in Formula One, Lorcana uses a **struct** to track multiple properties:

```swift
struct LorcanaState: Equatable {
    var cards: [LorcanaCard]
    var sets: [LorcanaSet]
    var searchQuery: String
    var currentPage: Int
    var hasMorePages: Bool
    var isLoading: Bool
    var isLoadingMore: Bool
    var error: LorcanaError?
    
    var isSearching: Bool {
        !searchQuery.isEmpty
    }
    
    static let initial = LorcanaState(
        cards: [],
        sets: [],
        searchQuery: "",
        currentPage: 1,
        hasMorePages: true,
        isLoading: false,
        isLoadingMore: false,
        error: nil
    )
}
```

This pattern is ideal when you have multiple independent concerns (loading, pagination, search) that can change simultaneously.

### Events

The events cover search, pagination, and data fetching:

```swift
enum LorcanaEvent: BlocEvent {
    case clear
    case fetchAllCards
    case loadNextPage
    case search(query: String)
    case loadSet(setName: String)
    case loadSets
}
```

### Bloc Implementation

The `LorcanaBloc` demonstrates pagination and search handling:

```swift
@MainActor
class LorcanaBloc: Bloc<LorcanaState, LorcanaEvent> {
    
    private let networkService: LorcanaNetworkService
    private let pageSize = 100
    
    override func mapEventToState(event: LorcanaEvent, emit: @escaping Emitter) {
        switch event {
        case .fetchAllCards:
            Task { await fetchAllCards(emit: emit) }
        case .loadNextPage:
            Task { await loadNextPage(emit: emit) }
        case .search(let query):
            Task { await searchCards(query: query, emit: emit) }
        // ...
        }
    }
    
    private func loadNextPage(emit: @escaping Emitter) async {
        // Don't load if already loading or no more pages
        guard !state.isLoadingMore && !state.isLoading && state.hasMorePages else { return }
        
        var newState = state
        newState.isLoadingMore = true
        emit(newState)
        
        let nextPage = state.currentPage + 1
        
        do {
            let cards = try await networkService.fetchAllCards(
                page: nextPage, 
                pageSize: pageSize
            )
            var loadedState = state
            loadedState.cards.append(contentsOf: cards)
            loadedState.currentPage = nextPage
            loadedState.isLoadingMore = false
            loadedState.hasMorePages = cards.count == pageSize
            emit(loadedState)
        } catch {
            var errorState = state
            errorState.isLoadingMore = false
            errorState.error = LorcanaError(message: error.localizedDescription)
            emit(errorState)
        }
    }
}
```

**Key Points:**

1. **Guard conditions**: Check if we should load more before starting
2. **Append, don't replace**: Add new cards to existing array for infinite scroll
3. **Track page state**: Update `currentPage` and check `hasMorePages`
4. **Separate loading states**: `isLoading` for initial load, `isLoadingMore` for pagination

### Debounced Search

The view implements debounced search to avoid excessive API calls:

```swift
@State private var searchText: String = ""
@State private var searchTask: Task<Void, Never>?

private func handleSearchChange(_ newValue: String) {
    // Cancel any pending search
    searchTask?.cancel()
    
    // Only search when we have 3+ characters
    guard newValue.count >= 3 else {
        if newValue.isEmpty {
            lorcanaBloc.send(.clear)
        }
        return
    }
    
    // Debounce the search with 0.3 second delay
    searchTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        guard !Task.isCancelled else { return }
        
        lorcanaBloc.send(.search(query: newValue))
    }
}
```

**Key Points:**

1. **Cancel previous task**: Always cancel pending searches when input changes
2. **Minimum character count**: Only trigger API calls after 3+ characters
3. **Debounce delay**: Wait 0.3 seconds of inactivity before searching
4. **Check cancellation**: Ensure task wasn't cancelled before sending event

### Infinite Scroll Trigger

The list triggers loading when the last item appears:

```swift
LazyVStack(spacing: 12) {
    ForEach(lorcanaBloc.state.cards) { card in
        NavigationLink(destination: LorcanaCardDetailView(card: card)) {
            cardRow(card: card)
        }
        .onAppear {
            // Trigger load more when last item appears
            if card == lorcanaBloc.state.cards.last {
                lorcanaBloc.send(.loadNextPage)
            }
        }
    }
    
    // Loading indicator
    if lorcanaBloc.state.isLoadingMore {
        HStack(spacing: 12) {
            ProgressView().tint(.purple)
            Text("Loading more...")
        }
    }
}
```

### Dynamic Theming

Cards adapt their colors based on ink type:

```swift
enum InkColor: String {
    case amber, amethyst, emerald, ruby, sapphire, steel
    case unknown
}

private func inkColorForCard(_ card: LorcanaCard) -> Color {
    switch card.inkColor {
    case .amber: return Color(red: 1.0, green: 0.75, blue: 0.2)
    case .amethyst: return Color(red: 0.6, green: 0.3, blue: 0.9)
    case .emerald: return Color(red: 0.2, green: 0.75, blue: 0.4)
    case .ruby: return Color(red: 0.9, green: 0.2, blue: 0.3)
    case .sapphire: return Color(red: 0.2, green: 0.5, blue: 0.9)
    case .steel: return Color(red: 0.6, green: 0.6, blue: 0.65)
    case .unknown: return Color.gray
    }
}
```

This color is used for card borders, backgrounds, navigation bar tinting, and accent elements throughout the UI.

---

## Comparison: All Examples

| Aspect | Counter | Formula One | Lorcana |
|--------|---------|-------------|---------|
| State type | `Int` | `enum` | `struct` |
| Async | None | Single fetch | Paginated + Search |
| Pagination | No | No | Yes (infinite scroll) |
| Search | No | No | Yes (debounced) |
| Navigation | Single screen | Single screen | Multi-screen |
| Theming | Static | Static | Dynamic (per-card) |

---

## Next Steps

Now that you've seen these examples, try:

1. **Extend the Counter**: Add multiply/divide operations
2. **Add Persistence**: Save counter value to UserDefaults
3. **Create Your Own**: Build a todo list or timer feature
4. **Write Tests**: Unit test your Bloc's event handlers
5. **Add Filters**: Extend Lorcana with filter by ink color or rarity
