# Changelog

All notable changes to the Bloc library will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.1] - 2026-09-22

Demo app fixes and design-system consistency pass. No changes to the `Bloc` library itself.

### Fixed
- **Lorcana** — a new search now cancels the previous in-flight request, so a slow stale response can no longer overwrite newer results
- **Lorcana** — search bar placeholder text now uses a themed color instead of the barely-visible default
- **Examples sidebar** — "State Management Patterns" subtitle, "Built with Swift" footer, and the welcome panel description are no longer barely visible in dark mode (replaced the system-adaptive `.secondary` color, which doesn't suit the app's always-dark chrome, with themed tokens)

### Changed
- **Score**, **Timer**, **Formula One** — text colors now use `Theme.Palette` tokens instead of hardcoded system/white colors, matching the rest of the design system
- Renamed leftover `BlocProject18*` template filenames (from the project's original Xcode template) to `BlocProject*`
- Demo app project now builds under Swift 6 / strict concurrency mode, with deployment targets normalized across all three Xcode targets

### Fixed (internal)
- Fixed a `Sendable` conformance gap in `LorcanaNetworkService` surfaced by Swift 6 mode
- Fixed `CounterBlocTests` leaking `HydratedBloc` state between test runs via real `UserDefaults` instead of an in-memory store

---

## [1.1.0] - 2026-04-17

### Added
- `.spi.yml` Swift Package Index build configuration (iOS, macOS, tvOS, watchOS)
- `swift-docc-plugin` dependency for generating DocC documentation
- GitHub issue/PR templates, `SECURITY.md`, and a docs-publishing GitHub Actions workflow

### Changed
- `LICENSE` updated with an AI/ML training-restriction clause on top of Apache 2.0
- Expanded `README.md` with additional usage guidance
- Demo app polish across the Calculator, Counter, Formula One, Heartbeat, Lorcana, Score, and Timer examples

---

## [1.0.0] - 2026-04-17

Initial public release.

### Added
- `Bloc<State, Event>` base class with event handler registration via `on(_:handler:)`
- `Cubit<State>` base class for simpler state management without events
- `BlocProvider` for registering Blocs into the SwiftUI environment
- `BlocRegistry` for type-safe Bloc resolution
- `BlocBuilder` for state-driven view rebuilding
- `BlocListener` for side effects in response to state changes
- `BlocSelector` for deriving sub-state and preventing unnecessary rebuilds
- `BlocConsumer` combining `BlocBuilder` and `BlocListener` in a single widget
- `HydratedBloc` for automatic state persistence and rehydration
- `EventTransformer` support: sequential, concurrent, droppable, restartable, debounce, throttle
- `BlocObserver` for global lifecycle monitoring (onCreate, onChange, onTransition, onError, onClose)
- Lifecycle hooks: `onEvent`, `onChange`, `onTransition`, `onError` overrides on `Bloc`
- `buildWhen` and `listenWhen` predicates for fine-grained rebuild/listen control
- `close()` for scoped Bloc lifecycle management
- Swift 6 / strict concurrency support
- Combine `statePublisher` for reactive integrations
- Support for iOS 17+, macOS 14+, tvOS 17+, watchOS 10+
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

[Unreleased]: https://github.com/sergiofraile/BlocSwift/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/sergiofraile/BlocSwift/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sergiofraile/BlocSwift/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/sergiofraile/BlocSwift/releases/tag/v1.0.0
