import Foundation
import Testing
@testable import Bloc

// MARK: - In-Memory Storage

/// A lightweight, dictionary-backed HydratedStorage for unit tests.
/// Eliminates any dependency on UserDefaults, keeping tests hermetic.
final class InMemoryStorage: HydratedStorage, @unchecked Sendable {
    private var store: [String: Data] = [:]

    func read(key: String) -> Data? { store[key] }
    func write(key: String, value: Data) { store[key] = value }
    func delete(key: String) { store[key] = nil }
    func clear() { store.removeAll() }

    var storedKeys: [String] { Array(store.keys) }
}

// MARK: - Test Helpers

private enum HydratedEvent: BlocEvent { case increment, reset }

@MainActor
private class CounterHydratedBloc: HydratedBloc<Int, HydratedEvent> {
    init(storage: HydratedStorage = InMemoryStorage()) {
        super.init(initialState: 0, storage: storage)
        on(.increment) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
        on(.reset) { _, emit in emit(0) }
    }
}

@MainActor
private class CustomKeyBloc: HydratedBloc<Int, HydratedEvent> {
    override class var storageKey: String { "custom_counter_key" }

    init(storage: HydratedStorage) {
        super.init(initialState: 0, storage: storage)
        on(.increment) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
    }
}

// MARK: - HydratedBloc Tests

@MainActor
struct HydratedBlocTests {

    // MARK: Rehydration

    @Test func usesInitialStateWhenStorageIsEmpty() {
        let bloc = CounterHydratedBloc()
        #expect(bloc.state == 0)
    }

    @Test func rehydratesStateFromStorageOnInit() throws {
        let storage = InMemoryStorage()

        // Write a previously persisted state (value = 5)
        let data = try #require(try? JSONEncoder().encode(5))
        storage.write(key: "CounterHydratedBloc", value: data)

        // A new bloc instance should restore the persisted value
        let bloc = CounterHydratedBloc(storage: storage)
        #expect(bloc.state == 5)
    }

    // MARK: Persistence

    @Test func persistsStateToStorageAfterEveryEmit() {
        let storage = InMemoryStorage()
        let bloc = CounterHydratedBloc(storage: storage)

        bloc.send(.increment)
        bloc.send(.increment)

        // The written value should equal the current state
        let data = storage.read(key: "CounterHydratedBloc")
        let persisted = data.flatMap { try? JSONDecoder().decode(Int.self, from: $0) }
        #expect(persisted == 2)
    }

    // MARK: Clearing State

    @Test func clearStoredStateRemovesDataFromStorage() {
        let storage = InMemoryStorage()
        let bloc = CounterHydratedBloc(storage: storage)

        bloc.send(.increment)
        #expect(!storage.storedKeys.isEmpty)

        bloc.clearStoredState()
        #expect(storage.read(key: "CounterHydratedBloc") == nil)

        // In-memory state is unaffected
        #expect(bloc.state == 1)
    }

    @Test func resetToInitialStateEmitsInitialValueAndClearsStorage() {
        let storage = InMemoryStorage()
        let bloc = CounterHydratedBloc(storage: storage)

        bloc.send(.increment)
        bloc.send(.increment)
        #expect(bloc.state == 2)

        bloc.resetToInitialState()
        #expect(bloc.state == 0)

        // resetToInitialState clears and immediately re-writes initialState
        let data = storage.read(key: "CounterHydratedBloc")
        let persisted = data.flatMap { try? JSONDecoder().decode(Int.self, from: $0) }
        #expect(persisted == 0)
    }

    // MARK: Custom Storage Key

    @Test func usesCustomStorageKeyWhenOverridden() {
        let storage = InMemoryStorage()
        let bloc = CustomKeyBloc(storage: storage)

        bloc.send(.increment)

        // State must be stored under the custom key, not the class name
        #expect(storage.read(key: "custom_counter_key") != nil)
        #expect(storage.read(key: "CustomKeyBloc") == nil)
    }
}
