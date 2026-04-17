import Testing
@testable import Bloc

// MARK: - Test Helpers

private enum ObserverTestEvent: BlocEvent { case fire }

@MainActor
private class SimpleBloc: Bloc<Int, ObserverTestEvent> {
    init() {
        super.init(initialState: 0)
        on(.fire) { [weak self] _, emit in
            guard let self else { return }
            emit(self.state + 1)
        }
    }
}

@MainActor
private class SimpleCubit: Cubit<Int> {
    init() { super.init(initialState: 0) }
    func increment() { emit(state + 1) }
}

private enum ObserverError: Error { case test }

// MARK: - Tracking Observer

/// A BlocObserver subclass that records every lifecycle call.
@MainActor
private class TrackingObserver: BlocObserver {
    var createdCount = 0
    var eventCount = 0
    var changeCount = 0
    var transitionCount = 0
    var errorCount = 0
    var closeCount = 0

    override func onCreate(_ emitter: any StateEmitter) {
        createdCount += 1
    }
    override func onEvent(_ bloc: any BlocBase, event: Any) {
        eventCount += 1
    }
    override func onChange(_ emitter: any StateEmitter, change: Any) {
        changeCount += 1
    }
    override func onTransition(_ bloc: any BlocBase, transition: Any) {
        transitionCount += 1
    }
    override func onError(_ emitter: any StateEmitter, error: Error) {
        errorCount += 1
    }
    override func onClose(_ emitter: any StateEmitter) {
        closeCount += 1
    }
}

// MARK: - BlocObserver Tests

@MainActor
struct BlocObserverTests {

    // Installs `observer` as the shared observer for the duration of a test,
    // then restores the original observer automatically.
    private func withTrackingObserver(_ body: (TrackingObserver) -> Void) {
        let original = BlocObserver.shared
        let observer = TrackingObserver()
        BlocObserver.shared = observer
        defer { BlocObserver.shared = original }
        body(observer)
    }

    // MARK: onCreate

    @Test func onCreateFiresWhenBlocIsInitialised() {
        withTrackingObserver { observer in
            _ = SimpleBloc()
            #expect(observer.createdCount == 1)
        }
    }

    @Test func onCreateFiresWhenCubitIsInitialised() {
        withTrackingObserver { observer in
            _ = SimpleCubit()
            #expect(observer.createdCount == 1)
        }
    }

    // MARK: onEvent

    @Test func onEventFiresWhenBlocReceivesAnEvent() {
        withTrackingObserver { observer in
            let bloc = SimpleBloc()
            observer.eventCount = 0 // reset count set during init
            bloc.send(.fire)
            bloc.send(.fire)
            #expect(observer.eventCount == 2)
        }
    }

    // MARK: onChange

    @Test func onChangeFiresWhenBlocEmitsNewState() {
        withTrackingObserver { observer in
            let bloc = SimpleBloc()
            observer.changeCount = 0
            bloc.send(.fire)
            #expect(observer.changeCount == 1)
        }
    }

    @Test func onChangeFiresWhenCubitEmitsNewState() {
        withTrackingObserver { observer in
            let cubit = SimpleCubit()
            observer.changeCount = 0
            cubit.increment()
            cubit.increment()
            #expect(observer.changeCount == 2)
        }
    }

    // MARK: onTransition

    @Test func onTransitionFiresForSynchronousBlocEmit() {
        withTrackingObserver { observer in
            let bloc = SimpleBloc()
            observer.transitionCount = 0
            bloc.send(.fire)
            #expect(observer.transitionCount == 1)
        }
    }

    // MARK: onError

    @Test func onErrorFiresWhenBlocCallsAddError() {
        withTrackingObserver { observer in
            let bloc = SimpleBloc()
            observer.errorCount = 0
            bloc.addError(ObserverError.test)
            #expect(observer.errorCount == 1)
        }
    }

    @Test func onErrorFiresWhenCubitCallsAddError() {
        withTrackingObserver { observer in
            let cubit = SimpleCubit()
            observer.errorCount = 0
            cubit.addError(ObserverError.test)
            #expect(observer.errorCount == 1)
        }
    }

    // MARK: onClose

    @Test func onCloseFiresWhenBlocIsClosed() {
        withTrackingObserver { observer in
            let bloc = SimpleBloc()
            observer.closeCount = 0
            bloc.close()
            #expect(observer.closeCount == 1)
        }
    }

    @Test func onCloseFiresWhenCubitIsClosed() {
        withTrackingObserver { observer in
            let cubit = SimpleCubit()
            observer.closeCount = 0
            cubit.close()
            #expect(observer.closeCount == 1)
        }
    }
}
