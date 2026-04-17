//
//  HydratedStorage.swift
//  Bloc
//

import Foundation

// MARK: - Protocol

/// A storage backend for persisting and restoring ``HydratedBloc`` state.
///
/// Implement this protocol to swap `UserDefaults` for any other store
/// (Keychain, a file, an in-memory dictionary for tests, etc.).
///
/// ```swift
/// // In-memory storage for unit tests
/// final class InMemoryStorage: HydratedStorage {
///     private var store: [String: Data] = [:]
///     func read(key: String) -> Data? { store[key] }
///     func write(key: String, value: Data) { store[key] = value }
///     func delete(key: String) { store[key] = nil }
///     func clear() { store.removeAll() }
/// }
/// ```
public protocol HydratedStorage {
    /// Returns the raw data previously written for `key`, or `nil` if absent.
    func read(key: String) -> Data?
    /// Persists `value` under `key`, replacing any existing entry.
    func write(key: String, value: Data)
    /// Removes the entry for `key`. No-op if the key does not exist.
    func delete(key: String)
    /// Removes **all** entries written by any ``HydratedBloc``.
    func clear()
}

// MARK: - UserDefaults implementation

/// A ``HydratedStorage`` implementation backed by `UserDefaults`.
///
/// All keys are prefixed with `"bloc.hydrated."` to avoid collisions with
/// other `UserDefaults` entries in the same app.
///
/// Use the shared singleton in production:
///
/// ```swift
/// class MyBloc: HydratedBloc<MyState, MyEvent> {
///     init() {
///         // storage: defaults to UserDefaultsStorage.shared
///         super.init(initialState: .initial)
///     }
/// }
/// ```
///
/// Inject a custom instance for tests:
///
/// ```swift
/// let inMemory = InMemoryStorage()
/// let bloc = MyBloc(initialState: .initial, storage: inMemory)
/// ```
public final class UserDefaultsStorage: HydratedStorage, @unchecked Sendable {

    /// The shared `UserDefaults.standard`-backed singleton.
    public static let shared = UserDefaultsStorage()

    private let defaults: UserDefaults
    /// Prefix applied to every key to avoid collisions with other UserDefaults entries.
    private let keyPrefix = "bloc.hydrated."

    /// Creates a storage instance backed by the given `UserDefaults` suite.
    ///
    /// - Parameter defaults: The `UserDefaults` suite to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func read(key: String) -> Data? {
        defaults.data(forKey: keyPrefix + key)
    }

    public func write(key: String, value: Data) {
        defaults.set(value, forKey: keyPrefix + key)
    }

    public func delete(key: String) {
        defaults.removeObject(forKey: keyPrefix + key)
    }

    /// Removes every key whose name starts with `"bloc.hydrated."`.
    public func clear() {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .forEach { defaults.removeObject(forKey: $0) }
    }

    // MARK: - Diagnostics

    /// All keys currently managed by HydratedBlocs, stripped of the prefix.
    public var storedKeys: [String] {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(keyPrefix) }
            .map { String($0.dropFirst(keyPrefix.count)) }
            .sorted()
    }
}
