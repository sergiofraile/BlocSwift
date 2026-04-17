# ``Bloc``

A predictable state management library for SwiftUI applications.

## Overview

Bloc (Business Logic Component) is a Swift implementation of the popular [Bloc pattern](https://bloclibrary.dev/), designed to help you build applications in a consistent and understandable way.

The library separates **presentation** from **business logic**, making your code:

- **Testable**: Business logic is isolated and easy to unit test
- **Predictable**: State changes only happen in response to events
- **Maintainable**: Clear separation of concerns
- **Observable**: SwiftUI automatically updates when state changes

### The Bloc Pattern

```
┌─────────────────────────────────────────────────────────┐
│                         View                            │
│   ┌─────────────┐                    ┌──────────────┐   │
│   │   Button    │────send(event)────▶│  bloc.state  │   │
│   └─────────────┘                    └──────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │                   ▲
                            ▼                   │
┌─────────────────────────────────────────────────────────┐
│                        Bloc                             │
│   ┌─────────────┐    ┌──────────────┐    ┌──────────┐   │
│   │    Event    │───▶│   Handler    │───▶│  emit()  │   │
│   └─────────────┘    └──────────────┘    └──────────┘   │
└─────────────────────────────────────────────────────────┘
```

1. **Views** send events to the Bloc
2. **Bloc** processes events through handlers
3. **Handlers** emit new states
4. **Views** automatically update when state changes

## Getting Started

### 1. Define Your Events

Events represent user actions or occurrences:

```swift
enum CounterEvent: Hashable {
    case increment
    case decrement
    case reset
}
```

### 2. Create Your Bloc

The Bloc contains your business logic:

```swift
@MainActor
class CounterBloc: Bloc<Int, CounterEvent> {
    init() {
        super.init(initialState: 0)
        
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

### 3. Provide the Bloc

Wrap your view hierarchy with ``BlocProvider``:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            BlocProvider(with: [CounterBloc()]) {
                ContentView()
            }
        }
    }
}
```

### 4. Use in Your View

Access state directly—SwiftUI handles the rest:

```swift
struct CounterView: View {
    let counterBloc = BlocRegistry.resolve(CounterBloc.self)
    
    var body: some View {
        Text("Count: \(counterBloc.state)")
        Button("+") { counterBloc.send(.increment) }
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Examples>
- ``Bloc``
- ``BlocProvider``
- ``BlocRegistry``

### State and Events

- ``BlocState``
- ``BlocEvent``

### Protocols

- ``BlocBase``

### Views

- ``BlocBuilder``

### Errors

- ``BlocError``
