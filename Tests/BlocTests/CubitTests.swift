import Testing
import Combine
@testable import Bloc

// MARK: - Test Helpers

@MainActor
private class CounterCubit: Cubit<Int> {
    init() { super.init(initialState: 0) }
    func increment() { emit(state + 1) }
    func decrement() { emit(state - 1) }
    func reset()     { emit(0) }
}

private enum TestError: Error, Equatable { case sample }

// MARK: - Cubit Tests

@MainActor
struct CubitTests {

    // MARK: State

    @Test func initialState() {
        let cubit = CounterCubit()
        #expect(cubit.state == 0)
    }

    @Test func emitUpdatesState() {
        let cubit = CounterCubit()
        cubit.increment()
        #expect(cubit.state == 1)
    }

    @Test func multipleEmitsAccumulate() {
        let cubit = CounterCubit()
        cubit.increment()
        cubit.increment()
        cubit.decrement()
        #expect(cubit.state == 1)
    }

    @Test func emitIsNoOpAfterClose() {
        let cubit = CounterCubit()
        cubit.close()
        cubit.increment()
        #expect(cubit.state == 0)
    }

    // MARK: Lifecycle

    @Test func closeSetsisClosed() {
        let cubit = CounterCubit()
        #expect(!cubit.isClosed)
        cubit.close()
        #expect(cubit.isClosed)
    }

    @Test func closeIsIdempotent() {
        let cubit = CounterCubit()
        cubit.close()
        cubit.close() // must not crash
        #expect(cubit.isClosed)
    }

    // MARK: Publishers

    @Test func statePublisherEmitsCurrentValueOnSubscription() {
        let cubit = CounterCubit()
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        // CurrentValueSubject replays the current value on subscription
        cubit.statePublisher.sink { received.append($0) }.store(in: &cancellables)
        #expect(received == [0])
    }

    @Test func statePublisherEmitsOnEveryEmit() {
        let cubit = CounterCubit()
        var received: [Int] = []
        var cancellables = Set<AnyCancellable>()

        cubit.statePublisher.sink { received.append($0) }.store(in: &cancellables)
        cubit.increment()
        cubit.increment()
        #expect(received == [0, 1, 2])
        withExtendedLifetime(cancellables) {}
    }

    @Test func errorsPublisherReceivesErrors() {
        let cubit = CounterCubit()
        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()

        cubit.errorsPublisher.sink { errors.append($0) }.store(in: &cancellables)
        cubit.addError(TestError.sample)
        #expect(errors.count == 1)
        #expect(errors.first as? TestError == .sample)
        withExtendedLifetime(cancellables) {}
    }

    @Test func addErrorIsNoOpAfterClose() {
        let cubit = CounterCubit()
        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()

        cubit.errorsPublisher.sink { errors.append($0) }.store(in: &cancellables)
        cubit.close()
        cubit.addError(TestError.sample)
        #expect(errors.isEmpty)
    }

    // MARK: Lifecycle Hooks

    @Test func onChangeHookFires() {
        class TrackingCubit: Cubit<Int> {
            var changes: [Change<Int>] = []
            init() { super.init(initialState: 0) }
            func increment() { emit(state + 1) }
            override func onChange(_ change: Change<Int>) {
                super.onChange(change)
                changes.append(change)
            }
        }

        let cubit = TrackingCubit()
        cubit.increment()

        #expect(cubit.changes.count == 1)
        #expect(cubit.changes[0].currentState == 0)
        #expect(cubit.changes[0].nextState == 1)
    }

    @Test func onErrorHookFires() {
        class TrackingCubit: Cubit<Int> {
            var receivedErrors: [Error] = []
            init() { super.init(initialState: 0) }
            override func onError(_ error: Error) {
                super.onError(error)
                receivedErrors.append(error)
            }
        }

        let cubit = TrackingCubit()
        cubit.addError(TestError.sample)
        #expect(cubit.receivedErrors.count == 1)
    }

    @Test func onCloseHookFires() {
        class TrackingCubit: Cubit<Int> {
            var didClose = false
            init() { super.init(initialState: 0) }
            override func onClose() {
                super.onClose()
                didClose = true
            }
        }

        let cubit = TrackingCubit()
        cubit.close()
        #expect(cubit.didClose)
    }
}
