import Testing
@testable import Bloc

// MARK: - Test Helpers

private enum FireEvent: BlocEvent { case fire }

// MARK: - EventTransformer Tests

@MainActor
struct EventTransformerTests {

    // MARK: Sequential

    /// Sequential is the default: the handler is called synchronously inside
    /// `send`, so state is updated before `send` returns.
    @Test func sequentialProcessesHandlerSynchronously() {
        @MainActor
        class SequentialBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .sequential) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = SequentialBloc()
        bloc.send(.fire)
        // No await needed — sequential dispatches synchronously
        #expect(bloc.state == 1)
        bloc.send(.fire)
        #expect(bloc.state == 2)
    }

    // MARK: Droppable

    /// Droppable wraps the handler in a Task. Sending two events before the
    /// Task has a chance to run leaves an active entry in `activeTasks`, so
    /// the second and third sends are silently dropped.
    @Test func droppableDropsEventsWhileHandlerIsActive() async {
        @MainActor
        class DroppableBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .droppable) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = DroppableBloc()
        bloc.send(.fire) // Creates a Task (hasn't run yet)
        bloc.send(.fire) // activeTasks[.fire] != nil → dropped
        bloc.send(.fire) // activeTasks[.fire] != nil → dropped

        await Task.yield() // Let the single queued Task run

        #expect(bloc.state == 1) // Only one emission despite three sends
    }

    // MARK: Restartable

    /// Restartable cancels any pending Task and creates a new one. Sending
    /// two events before any Task runs means only the second Task executes
    /// (the first is cancelled before it starts).
    @Test func restartableCancelsPreviousTaskAndRunsLatest() async {
        @MainActor
        class RestartableBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .restartable) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = RestartableBloc()
        bloc.send(.fire) // Creates Task1
        bloc.send(.fire) // Cancels Task1, creates Task2

        await Task.yield() // Task1 exits early (isCancelled), Task2 runs

        #expect(bloc.state == 1) // Only the second Task's emission is applied
    }

    // MARK: Concurrent

    /// Concurrent gives each event its own independent Task.
    /// Both Tasks run and both emit, so the state reflects two increments.
    @Test func concurrentRunsAllHandlersIndependently() async {
        @MainActor
        class ConcurrentBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .concurrent) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = ConcurrentBloc()
        bloc.send(.fire) // Creates Task1
        bloc.send(.fire) // Creates Task2 (independent)

        await Task.yield() // Both Tasks run

        #expect(bloc.state == 2) // Two independent emissions
    }

    // MARK: Debounce

    /// Debounce cancels the pending timer when a new event arrives and
    /// restarts it. Only the last event's handler fires after the quiet period.
    @Test func debounceOnlyFiresAfterQuietPeriod() async throws {
        @MainActor
        class DebounceBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .debounce(.milliseconds(50))) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = DebounceBloc()
        bloc.send(.fire) // Starts 50 ms timer
        bloc.send(.fire) // Resets timer (first is cancelled)
        bloc.send(.fire) // Resets timer again

        try await Task.sleep(for: .milliseconds(150)) // Wait for debounce to settle

        #expect(bloc.state == 1) // Only one handler fired after the quiet period
    }

    // MARK: Throttle

    /// Throttle fires the handler immediately on the leading edge, then
    /// suppresses subsequent events for the cooldown duration.
    @Test func throttleFiresImmediatelyAndDropsEventsInCooldown() async {
        @MainActor
        class ThrottleBloc: Bloc<Int, FireEvent> {
            init() {
                super.init(initialState: 0)
                on(.fire, transformer: .throttle(.milliseconds(200))) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
        }

        let bloc = ThrottleBloc()
        bloc.send(.fire) // Fires synchronously (leading edge), starts cooldown Task
        #expect(bloc.state == 1) // Immediate — no await needed

        bloc.send(.fire) // Cooldown Task is still active → dropped
        bloc.send(.fire) // Still in cooldown → dropped

        await Task.yield() // Let the cooldown Task continue (it's just sleeping)

        #expect(bloc.state == 1) // Only the first event produced a state change
    }
}
