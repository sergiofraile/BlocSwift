# Getting Started

Build your first Bloc-powered feature in 5 minutes.

## Overview

This guide walks you through creating a simple counter feature using the Bloc pattern. You'll learn the core concepts and see how they fit together.

## Creating a Counter

### Step 1: Define Events

Events represent what can happen in your feature. For a counter, we have three possible actions:

```swift
enum CounterEvent: Hashable {
    case increment
    case decrement
    case reset
}
```

> Tip: Events must conform to `Hashable` (which includes `Equatable`). Using enums is the most common and recommended approach.

### Step 2: Create the Bloc

The Bloc is where your business logic lives. It receives events and produces new states:

```swift
import Bloc

@MainActor
class CounterBloc: Bloc<Int, CounterEvent> {
    
    init() {
        // Start with an initial state of 0
        super.init(initialState: 0)
        
        // Register handlers for each event
        on(.increment) { [weak self] event, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
        
        on(.decrement) { [weak self] event, emit in
            guard let self else { return }
            emit(self.state - 1)
        }
        
        on(.reset) { event, emit in
            emit(0)
        }
    }
}
```

Key points:
- `Bloc<Int, CounterEvent>` — The state is `Int`, events are `CounterEvent`
- `super.init(initialState: 0)` — Set the starting state
- `on(_:handler:)` — Register a handler for each event
- `emit(newState)` — Output a new state

> Important: Always use `[weak self]` when capturing `self` in handlers to avoid retain cycles.

### Step 3: Register with BlocProvider

Make your Bloc available to the view hierarchy:

```swift
import SwiftUI
import Bloc

@main
struct CounterApp: App {
    var body: some Scene {
        WindowGroup {
            BlocProvider(with: [
                CounterBloc()
            ]) {
                CounterView()
            }
        }
    }
}
```

### Step 4: Build the View

Access the Bloc and use its state directly:

```swift
struct CounterView: View {
    let counterBloc = BlocRegistry.resolve(CounterBloc.self)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(counterBloc.state)")
                .font(.largeTitle)
            
            HStack(spacing: 40) {
                Button("−") { counterBloc.send(.decrement) }
                Button("+") { counterBloc.send(.increment) }
            }
            .font(.title)
            
            Button("Reset") { counterBloc.send(.reset) }
        }
    }
}
```

That's it! The view automatically updates when the state changes—no manual subscription needed.

## How It Works

1. User taps the "+" button
2. `counterBloc.send(.increment)` sends the event
3. The registered handler runs: `emit(self.state + 1)`
4. State updates from `0` to `1`
5. SwiftUI detects the change and re-renders the `Text`

## Next Steps

Now that you understand the basics, explore more advanced topics:

- **Complex State**: Use structs for multi-property states
- **Async Operations**: Handle network requests and other async work
- **Events with Data**: Use associated values for parameterized events
- **Testing**: Write unit tests for your Blocs
