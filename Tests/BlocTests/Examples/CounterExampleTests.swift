// CounterExampleTests.swift
//
// Faithful inline replica of the Counter example from BlocSwift/Examples/Counter.
//
// The real CounterBloc is a HydratedBloc<Int, CounterEvent>, so it persists
// the count across app launches. These tests use InMemoryStorage to keep the
// suite hermetic (no UserDefaults involvement) while still exercising the full
// HydratedBloc persistence path.

import Testing
@testable import Bloc

// MARK: - Inline replica of the Counter example

private enum CounterEvent: BlocEvent {
    case increment
    case decrement
    case reset
}

@MainActor
private class CounterBloc: HydratedBloc<Int, CounterEvent> {

    static let initialCount = 0

    init(storage: HydratedStorage = InMemoryStorage()) {
        super.init(initialState: Self.initialCount, storage: storage)

        on(.increment) { [weak self] _, emit in
            guard let self else { return }
            emit(state + 1)
        }
        on(.decrement) { [weak self] _, emit in
            guard let self else { return }
            emit(state - 1)
        }
        on(.reset) { _, emit in
            emit(Self.initialCount)
        }
    }
}

// MARK: - Tests

@MainActor
struct CounterExampleTests {

    @Test("CounterBloc starts at zero")
    func initialStateIsZero() {
        let bloc = CounterBloc()
        #expect(bloc.state == 0)
    }

    @Test("Increment raises the count")
    func incrementRaisesCount() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.increment)
        #expect(bloc.state == 3)
    }

    @Test("Decrement lowers the count, allowing negative values")
    func decrementLowersCount() {
        let bloc = CounterBloc()
        bloc.send(.decrement)
        #expect(bloc.state == -1)
    }

    @Test("Reset returns the count to zero from any value")
    func resetReturnsToZero() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.reset)
        #expect(bloc.state == 0)
    }

    @Test("HydratedBloc rehydrates the count from a previous session")
    func rehydratesPersistedCountOnInit() throws {
        let storage = InMemoryStorage()
        let firstSession = CounterBloc(storage: storage)
        firstSession.send(.increment)
        firstSession.send(.increment)
        firstSession.send(.increment)
        #expect(firstSession.state == 3)

        // Simulate a new app launch by creating a new bloc instance with the
        // same storage. The count should be restored automatically.
        let secondSession = CounterBloc(storage: storage)
        #expect(secondSession.state == 3)
    }
}
