//
//  HydratedBloc.swift
//  Bloc
//

import Foundation

// MARK: - AnyHydratedBloc

/// Type-erased protocol that lets `BlocRegistry` reset all hydrated Blocs
/// without knowing their concrete `State` or `Event` types.
@MainActor
public protocol AnyHydratedBloc: AnyObject {
    /// Removes this Bloc's persisted state from storage.
    /// The Bloc continues running with its current in-memory state.
    func clearStoredState()
    /// Clears persisted storage **and** immediately emits `initialState`,
    /// resetting the Bloc without requiring an app restart.
    func resetToInitialState()
}

// MARK: - HydratedBloc

/// A `Bloc` subclass that automatically persists its state across app launches.
///
/// `HydratedBloc` adds two behaviours on top of the standard ``Bloc``:
///
/// 1. **Rehydration on init** — the last-emitted state is read from
///    ``HydratedStorage`` (defaults to `UserDefaults`) and used as the
///    starting state instead of `initialState`.
///
/// 2. **Automatic persistence on every emit** — whenever ``emit(_:)`` is
///    called, the new state is encoded as JSON and written to storage.
///
/// ## Rehydration only happens at creation time
///
/// There is no way to "re-pull" saved state into a running Bloc mid-session.
/// Use ``resetToInitialState()`` to clear storage and immediately snap the
/// Bloc back to its starting value, or use ``clearStoredState()`` to wipe
/// storage so the *next* launch starts clean.
///
/// ## Usage
///
/// ```swift
/// // State must be Codable
/// struct CounterState: BlocState, Codable {
///     var count: Int = 0
/// }
///
/// class CounterBloc: HydratedBloc<CounterState, CounterEvent> {
///     init() {
///         super.init(initialState: CounterState())
///         on(.increment) { [weak self] _, emit in
///             guard let self else { return }
///             emit(CounterState(count: state.count + 1))
///         }
///     }
/// }
/// ```
///
/// ## Custom storage key
///
/// By default the key is the concrete class name (e.g. `"CounterBloc"`).
/// Override ``storageKey`` to use something more stable if you rename the class:
///
/// ```swift
/// override class var storageKey: String { "my_counter_v1" }
/// ```
///
/// ## Custom storage backend
///
/// Pass any ``HydratedStorage`` conformer to `super.init`:
///
/// ```swift
/// // Inject an in-memory store for tests
/// super.init(initialState: .initial, storage: InMemoryStorage())
/// ```
///
/// ## Clearing state
///
/// ```swift
/// // Wipe storage only (current state unchanged; next launch starts fresh)
/// bloc.clearStoredState()
///
/// // Wipe storage AND reset current state immediately (no restart needed)
/// bloc.resetToInitialState()
/// ```
@MainActor
open class HydratedBloc<S: BlocState & Codable, E: BlocEvent>: Bloc<S, E>, AnyHydratedBloc {

    // MARK: - Storage key

    /// The key used to persist this Bloc's state in ``HydratedStorage``.
    ///
    /// Defaults to the concrete class name. Override to provide a stable key
    /// that survives class renames or to support multiple instances of the
    /// same class with different data:
    ///
    /// ```swift
    /// // Versioned key — safe to rename the class later
    /// override class var storageKey: String { "settings_bloc_v2" }
    /// ```
    open class var storageKey: String { String(describing: Self.self) }

    // MARK: - Private state

    private let storage: HydratedStorage
    private let initialStateValue: S

    // MARK: - Init

    /// Creates a `HydratedBloc`, rehydrating from `storage` if a persisted
    /// state exists, otherwise using `initialState`.
    ///
    /// - Parameters:
    ///   - initialState: The state to use when no persisted value is found.
    ///   - storage: The backend to read and write state. Defaults to
    ///     `UserDefaultsStorage.shared`.
    public init(initialState: S, storage: HydratedStorage = UserDefaultsStorage.shared) {
        self.storage = storage
        self.initialStateValue = initialState
        // Read and decode any previously persisted state.
        // `Self.storageKey` resolves to the concrete subclass's key because
        // Swift dispatches class properties through the dynamic metatype.
        let key = Self.storageKey
        let restoredState = storage.read(key: key)
            .flatMap { try? JSONDecoder().decode(S.self, from: $0) }
        super.init(initialState: restoredState ?? initialState)
    }

    // MARK: - Persistence on emit

    /// Emits `state` and immediately persists it to storage.
    ///
    /// The persistence write is skipped if the Bloc has been closed.
    override public func emit(_ state: S) {
        super.emit(state)
        guard !isClosed else { return }
        if let data = try? JSONEncoder().encode(state) {
            storage.write(key: Self.storageKey, value: data)
        }
    }

    // MARK: - Storage management

    /// Removes this Bloc's persisted state from storage.
    ///
    /// The Bloc continues running with its current in-memory state unchanged.
    /// The next app launch will start from `initialState` because no persisted
    /// value will be found:
    ///
    /// ```swift
    /// // "Log out" scenario: wipe state without resetting the current session
    /// userBloc.clearStoredState()
    /// ```
    public func clearStoredState() {
        storage.delete(key: Self.storageKey)
    }

    /// Clears persisted storage **and** immediately emits `initialState`.
    ///
    /// Use this when you need an instant reset without restarting the app:
    ///
    /// ```swift
    /// // Reset button: wipe storage + reset UI immediately
    /// bloc.resetToInitialState()
    /// ```
    ///
    /// After this call:
    /// - The Bloc's in-memory state is `initialState`.
    /// - The storage key is removed, then immediately re-written with the
    ///   encoded `initialState` (because `emit` always persists).
    ///
    /// - Note: If you only want the *next* launch to start clean (without
    ///   affecting the current session), call ``clearStoredState()`` instead.
    public func resetToInitialState() {
        clearStoredState()
        emit(initialStateValue)
    }
}
