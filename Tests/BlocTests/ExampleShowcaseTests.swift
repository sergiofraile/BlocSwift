import Testing
import Combine
@testable import Bloc

// MARK: - Example Showcase
//
// These tests demonstrate how straightforward it is to unit-test a Bloc or
// Cubit implementation. No mocking framework is needed — just create the
// object, send events (or call methods), and assert on `state`.
//
// Both examples below mirror common real-world Blocs you would write in a
// project, and each test reads almost like a plain-English specification.

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - CounterBloc Example
// ─────────────────────────────────────────────────────────────────────────────

private enum CounterEvent: BlocEvent {
    case increment
    case decrement
    case reset
}

@MainActor
private class CounterBloc: Bloc<Int, CounterEvent> {
    init() {
        super.init(initialState: 0)
        on(.increment) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
        on(.decrement) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state - 1)
        }
        on(.reset) { _, emit in emit(0) }
    }
}

@MainActor
struct CounterBlocTests {

    @Test("CounterBloc starts at zero")
    func initialStateIsZero() {
        let bloc = CounterBloc()
        #expect(bloc.state == 0)
    }

    @Test("Increment event increases state by one")
    func incrementAddsOne() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        #expect(bloc.state == 2)
    }

    @Test("Decrement event decreases state by one")
    func decrementSubtractsOne() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.decrement)
        #expect(bloc.state == 1)
    }

    @Test("Reset event returns state to zero regardless of current value")
    func resetReturnToZero() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.reset)
        #expect(bloc.state == 0)
    }

    @Test("State transitions are observable via statePublisher")
    func statePublisherEmitsAllTransitions() {
        let bloc = CounterBloc()
        var history: [Int] = []
        var cancellables = Set<AnyCancellable>()

        bloc.statePublisher.sink { history.append($0) }.store(in: &cancellables)
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.reset)

        #expect(history == [0, 1, 2, 0])
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - StopwatchCubit Example
// ─────────────────────────────────────────────────────────────────────────────
// A Cubit is even simpler to test: just call methods and assert on state.

private struct StopwatchState: BlocState {
    let elapsedSeconds: Int
    let isRunning: Bool

    static let initial = StopwatchState(elapsedSeconds: 0, isRunning: false)
}

@MainActor
private class StopwatchCubit: Cubit<StopwatchState> {
    init() { super.init(initialState: .initial) }

    func start()  { emit(StopwatchState(elapsedSeconds: state.elapsedSeconds, isRunning: true)) }
    func tick()   { emit(StopwatchState(elapsedSeconds: state.elapsedSeconds + 1, isRunning: state.isRunning)) }
    func pause()  { emit(StopwatchState(elapsedSeconds: state.elapsedSeconds, isRunning: false)) }
    func reset()  { emit(.initial) }
}

@MainActor
struct StopwatchCubitTests {

    @Test("StopwatchCubit starts stopped at zero seconds")
    func initialStateIsStoppedAtZero() {
        let cubit = StopwatchCubit()
        #expect(cubit.state.elapsedSeconds == 0)
        #expect(!cubit.state.isRunning)
    }

    @Test("start() sets isRunning to true")
    func startSetsIsRunning() {
        let cubit = StopwatchCubit()
        cubit.start()
        #expect(cubit.state.isRunning)
    }

    @Test("tick() increments elapsed time")
    func tickIncrementsElapsedTime() {
        let cubit = StopwatchCubit()
        cubit.start()
        cubit.tick()
        cubit.tick()
        cubit.tick()
        #expect(cubit.state.elapsedSeconds == 3)
    }

    @Test("pause() sets isRunning to false while preserving elapsed time")
    func pausePreservesElapsedTime() {
        let cubit = StopwatchCubit()
        cubit.start()
        cubit.tick()
        cubit.tick()
        cubit.pause()
        #expect(!cubit.state.isRunning)
        #expect(cubit.state.elapsedSeconds == 2)
    }

    @Test("reset() returns to initial state")
    func resetRestoresInitialState() {
        let cubit = StopwatchCubit()
        cubit.start()
        cubit.tick()
        cubit.tick()
        cubit.reset()
        #expect(cubit.state.elapsedSeconds == 0)
        #expect(!cubit.state.isRunning)
    }
}
