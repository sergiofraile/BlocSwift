# Changelog

All notable changes to the Bloc library will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- `BlocSelector` for deriving sub-state and preventing unnecessary rebuilds
- `BlocConsumer` combining `BlocBuilder` and `BlocListener` in a single widget
- `HydratedBloc` for automatic state persistence and rehydration
- `EventTransformer` support: sequential, concurrent, droppable, restartable, debounce, throttle
- `BlocObserver` for global lifecycle monitoring (onCreate, onChange, onTransition, onError, onClose)
- Lifecycle hooks: `onEvent`, `onChange`, `onTransition`, `onError` overrides on `Bloc`
- `buildWhen` and `listenWhen` predicates for fine-grained rebuild/listen control
- `close()` for scoped Bloc lifecycle management
- Cubit support as a simpler alternative to Bloc (no events required)
- DocC documentation with articles and tutorials

### Examples Added
- **Counter** — HydratedBloc with state persistence via UserDefaults
- **Timer** — Cubit-based stopwatch with async tick loop
- **Calculator** — Bloc lifecycle hooks demonstration
- **Heartbeat** — Scoped Bloc with `close()` on screen dismiss
- **Score** — BlocListener for milestones, BlocConsumer for tier badges
- **Formula One** — Async API, loading/error states, driver standings
- **Lorcana** — Debounced search, infinite scroll pagination, BlocSelector, multi-screen navigation

---

## [1.0.0] - TBD

Initial public release.

### Added
- `Bloc<State, Event>` base class with event handler registration via `on(_:handler:)`
- `Cubit<State>` base class for simpler state management without events
- `BlocProvider` for registering Blocs into the SwiftUI environment
- `BlocRegistry` for type-safe Bloc resolution
- `BlocBuilder` for state-driven view rebuilding
- `BlocListener` for side effects in response to state changes
- Swift 6 / strict concurrency support
- Combine `statePublisher` for reactive integrations
- Support for iOS 17+, macOS 14+, tvOS 17+, watchOS 10+

---

[Unreleased]: https://github.com/sergiofraile/BlocSwift/compare/1.0.0...HEAD
[1.0.0]: https://github.com/sergiofraile/BlocSwift/releases/tag/1.0.0
