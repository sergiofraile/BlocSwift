// HeartbeatExampleTests.swift
//
// Faithful inline replica of the Heartbeat example from BlocSwift/Examples/Heartbeat.
//
// HeartbeatBloc demonstrates **scoped lifecycle management**: the view creates
// the Bloc itself and calls close() in onDisappear. The tests here verify:
//
//  - start sets the running flag and resets the tick count
//  - tick increments the count while the Bloc is running
//  - close() cancels the internal ticker Task immediately
//  - The Bloc can be driven without any real wall-clock waiting by sending
//    .tick events directly — this is a good pattern for testing async Blocs
//    that have internal timers: decouple the "what to do on tick" logic from
//    the "wait one second" scheduling logic.

import Testing
@testable import Bloc

// MARK: - Types

private enum HeartbeatEvent: BlocEvent {
    case start
    case tick
}

private struct HeartbeatState: BlocState {
    var tickCount: Int
    var isRunning: Bool

    static let initial = HeartbeatState(tickCount: 0, isRunning: false)
}

// MARK: - Inline replica of HeartbeatBloc (without BlocLifecycleLog)

@MainActor
private class HeartbeatBloc: Bloc<HeartbeatState, HeartbeatEvent> {

    private var tickerTask: Task<Void, Never>?

    init() {
        super.init(initialState: .initial)

        on(.start) { [weak self] _, emit in
            guard let self else { return }
            emit(HeartbeatState(tickCount: 0, isRunning: true))
            self.tickerTask = Task { [weak self] in
                while let bloc = self, !bloc.isClosed {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    guard let bloc = self, !bloc.isClosed else { break }
                    bloc.send(.tick)
                }
            }
        }

        on(.tick) { [weak self] _, emit in
            guard let self else { return }
            emit(HeartbeatState(tickCount: state.tickCount + 1, isRunning: true))
        }
    }

    override func onClose() {
        super.onClose()
        tickerTask?.cancel()
        tickerTask = nil
    }
}

// MARK: - Tests

@MainActor
struct HeartbeatExampleTests {

    @Test("HeartbeatBloc starts stopped with zero ticks")
    func initialStateIsStoppedAtZero() {
        let bloc = HeartbeatBloc()
        #expect(bloc.state.tickCount == 0)
        #expect(!bloc.state.isRunning)
    }

    @Test("start event sets isRunning and resets the tick count to zero")
    func startEventSetsRunning() {
        let bloc = HeartbeatBloc()
        bloc.send(.start)
        #expect(bloc.state.isRunning)
        #expect(bloc.state.tickCount == 0)
    }

    @Test("Each tick event increments the tick count by one")
    func tickEventIncrementsCount() {
        let bloc = HeartbeatBloc()
        bloc.send(.start)
        bloc.send(.tick)
        bloc.send(.tick)
        bloc.send(.tick)
        #expect(bloc.state.tickCount == 3)
    }

    @Test("close() cancels the internal ticker so send() becomes a no-op")
    func closeStopsTheTicker() async {
        let bloc = HeartbeatBloc()
        bloc.send(.start)
        bloc.send(.tick)
        #expect(bloc.state.tickCount == 1)

        bloc.close()
        #expect(bloc.isClosed)

        // After close, further tick events must be ignored
        bloc.send(.tick)
        #expect(bloc.state.tickCount == 1)
    }
}
