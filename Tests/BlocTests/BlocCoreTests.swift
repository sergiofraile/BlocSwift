import Testing
import Combine
@testable import Bloc

// MARK: - Test Helpers

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
        on(.reset) { _, emit in
            emit(0)
        }
    }
}

private enum BlocTestError: Error, Equatable { case sample }

// MARK: - Bloc Core Tests

@MainActor
struct BlocCoreTests {

    // MARK: State

    @Test func initialState() {
        let bloc = CounterBloc()
        #expect(bloc.state == 0)
    }

    @Test func sendDispatchesRegisteredHandler() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        #expect(bloc.state == 1)
    }

    @Test func multipleEventsProcessedInOrder() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.decrement)
        #expect(bloc.state == 1)
    }

    @Test func resetEventSetsStateToInitial() {
        let bloc = CounterBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        bloc.send(.reset)
        #expect(bloc.state == 0)
    }

    // MARK: Fallback & Pattern Handlers

    @Test func mapEventToStateFallbackIsCalledWhenNoHandlerRegistered() {
        enum FallbackEvent: BlocEvent { case ping, pong }

        @MainActor
        class FallbackBloc: Bloc<String, FallbackEvent> {
            init() { super.init(initialState: "") }
            override func mapEventToState(event: FallbackEvent, emit: @escaping Emitter) {
                switch event {
                case .ping: emit("ping")
                case .pong: emit("pong")
                }
            }
        }

        let bloc = FallbackBloc()
        bloc.send(.ping)
        #expect(bloc.state == "ping")
        bloc.send(.pong)
        #expect(bloc.state == "pong")
    }

    @Test func patternHandlerMatchesEventsByPredicate() {
        enum SearchEvent: BlocEvent {
            case search(query: String)
            case clear
        }

        @MainActor
        class SearchBloc: Bloc<String, SearchEvent> {
            init() {
                super.init(initialState: "")
                on(where: { if case .search = $0 { return true }; return false }) { event, emit in
                    if case .search(let query) = event { emit(query) }
                }
                on(.clear) { _, emit in emit("") }
            }
        }

        let bloc = SearchBloc()
        bloc.send(.search(query: "swift"))
        #expect(bloc.state == "swift")
        bloc.send(.clear)
        #expect(bloc.state == "")
    }

    // MARK: Close Behaviour

    @Test func sendIsNoOpAfterClose() {
        let bloc = CounterBloc()
        bloc.close()
        bloc.send(.increment)
        #expect(bloc.state == 0)
    }

    @Test func emitIsNoOpAfterClose() {
        let bloc = CounterBloc()
        bloc.close()
        bloc.emit(99)
        #expect(bloc.state == 0)
    }

    @Test func closeSetsisClosed() {
        let bloc = CounterBloc()
        #expect(!bloc.isClosed)
        bloc.close()
        #expect(bloc.isClosed)
    }

    @Test func closeIsIdempotent() {
        let bloc = CounterBloc()
        bloc.close()
        bloc.close() // must not crash
        #expect(bloc.isClosed)
    }

    // MARK: Publishers

    @Test func eventsPublisherEmitsEveryDispatchedEvent() {
        let bloc = CounterBloc()
        var received: [CounterEvent] = []
        var cancellables = Set<AnyCancellable>()

        bloc.eventsPublisher.sink { received.append($0) }.store(in: &cancellables)
        bloc.send(.increment)
        bloc.send(.decrement)
        #expect(received == [.increment, .decrement])
        withExtendedLifetime(cancellables) {}
    }

    @Test func statePublisherEmitsCurrentValueOnSubscription() {
        let bloc = CounterBloc()
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        // CurrentValueSubject replays current value on subscription
        bloc.statePublisher.sink { received.append($0) }.store(in: &cancellables)
        #expect(received == [0])
    }

    @Test func statePublisherEmitsOnEveryStateChange() {
        let bloc = CounterBloc()
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        bloc.statePublisher.sink { received.append($0) }.store(in: &cancellables)
        bloc.send(.increment)
        bloc.send(.increment)
        #expect(received == [0, 1, 2])
        withExtendedLifetime(cancellables) {}
    }

    @Test func errorsPublisherReceivesErrors() {
        let bloc = CounterBloc()
        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()

        bloc.errorsPublisher.sink { errors.append($0) }.store(in: &cancellables)
        bloc.addError(BlocTestError.sample)
        #expect(errors.count == 1)
        #expect(errors.first as? BlocTestError == .sample)
        withExtendedLifetime(cancellables) {}
    }

    // MARK: Lifecycle Hooks

    @Test func onEventHookFiresBeforeHandlerExecution() {
        @MainActor
        class TrackingBloc: Bloc<Int, CounterEvent> {
            var receivedEvents: [CounterEvent] = []
            init() {
                super.init(initialState: 0)
                on(.increment) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
            override func onEvent(_ event: CounterEvent) {
                super.onEvent(event)
                receivedEvents.append(event)
            }
        }

        let bloc = TrackingBloc()
        bloc.send(.increment)
        bloc.send(.increment)
        #expect(bloc.receivedEvents == [.increment, .increment])
    }

    @Test func onChangeHookFiresAfterEveryEmit() {
        @MainActor
        class TrackingBloc: Bloc<Int, CounterEvent> {
            var changes: [Change<Int>] = []
            init() {
                super.init(initialState: 0)
                on(.increment) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
            override func onChange(_ change: Change<Int>) {
                super.onChange(change)
                changes.append(change)
            }
        }

        let bloc = TrackingBloc()
        bloc.send(.increment)
        #expect(bloc.changes.count == 1)
        #expect(bloc.changes[0].currentState == 0)
        #expect(bloc.changes[0].nextState == 1)
    }

    @Test func onTransitionFiresForSynchronousEmit() {
        @MainActor
        class TrackingBloc: Bloc<Int, CounterEvent> {
            var transitions: [Transition<CounterEvent, Int>] = []
            init() {
                super.init(initialState: 0)
                on(.increment) { [weak self] _, emit in
                    guard let self else { return }
                    emit(self.state + 1)
                }
            }
            override func onTransition(_ transition: Transition<CounterEvent, Int>) {
                super.onTransition(transition)
                transitions.append(transition)
            }
        }

        let bloc = TrackingBloc()
        bloc.send(.increment)

        #expect(bloc.transitions.count == 1)
        #expect(bloc.transitions[0].currentState == 0)
        #expect(bloc.transitions[0].event == .increment)
        #expect(bloc.transitions[0].nextState == 1)
    }

    @Test func onTransitionDoesNotFireForAsyncEmit() async {
        // When emit is called from inside a Task, currentEvent is nil — so
        // onTransition should NOT fire. Only onChange fires for async emissions.
        @MainActor
        class AsyncBloc: Bloc<Int, CounterEvent> {
            var transitionCount = 0
            init() {
                super.init(initialState: 0)
                on(.increment) { [weak self] _, _ in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.emit(self.state + 1)
                    }
                }
            }
            override func onTransition(_ transition: Transition<CounterEvent, Int>) {
                super.onTransition(transition)
                transitionCount += 1
            }
        }

        let bloc = AsyncBloc()
        bloc.send(.increment)
        await Task.yield() // Let the inner Task run

        #expect(bloc.state == 1)          // State did update
        #expect(bloc.transitionCount == 0) // But no transition fired
    }

    @Test func onErrorHookFires() {
        @MainActor
        class TrackingBloc: Bloc<Int, CounterEvent> {
            var receivedErrors: [Error] = []
            init() { super.init(initialState: 0) }
            override func onError(_ error: Error) {
                super.onError(error)
                receivedErrors.append(error)
            }
        }

        let bloc = TrackingBloc()
        bloc.addError(BlocTestError.sample)
        #expect(bloc.receivedErrors.count == 1)
    }

    @Test func onCloseHookFires() {
        @MainActor
        class TrackingBloc: Bloc<Int, CounterEvent> {
            var didClose = false
            init() { super.init(initialState: 0) }
            override func onClose() {
                super.onClose()
                didClose = true
            }
        }

        let bloc = TrackingBloc()
        bloc.close()
        #expect(bloc.didClose)
    }
}
