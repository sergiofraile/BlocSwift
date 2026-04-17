//
//  TimerCubit.swift
//  BlocSwift
//

import Bloc

/// A stopwatch Cubit that manages elapsed time through direct method calls.
///
/// `TimerCubit` is a canonical Cubit example. Instead of sending events through
/// a handler registry (as a ``Bloc`` would), you call methods directly:
///
/// ```swift
/// timerCubit.start()
/// timerCubit.pause()
/// timerCubit.reset()
/// ```
///
/// The Cubit owns its async tick loop — no events, no transformers needed.
///
/// ## Cubit vs Bloc for this use-case
///
/// A Bloc would require `TimerEvent` (.start, .pause, .reset) and the same
/// internal `Task` management written inside event handlers. The Cubit version
/// is shorter, more readable, and equally testable — ideal for simple,
/// method-driven state.
@MainActor
class TimerCubit: Cubit<TimerState> {

    private var tickTask: Task<Void, Never>?

    init() {
        super.init(initialState: TimerState(elapsed: 0, isRunning: false))
    }

    // MARK: - Public API

    /// Starts the stopwatch if it is not already running.
    func start() {
        guard !state.isRunning else { return }
        emit(TimerState(elapsed: state.elapsed, isRunning: true))
        scheduleTick()
    }

    /// Pauses the stopwatch, preserving the current elapsed time.
    func pause() {
        guard state.isRunning else { return }
        tickTask?.cancel()
        emit(TimerState(elapsed: state.elapsed, isRunning: false))
    }

    /// Resets the stopwatch to zero and stops it.
    func reset() {
        tickTask?.cancel()
        emit(TimerState(elapsed: 0, isRunning: false))
    }

    // MARK: - Lifecycle

    override func onClose() {
        super.onClose()
        tickTask?.cancel()
    }

    // MARK: - Private

    private func scheduleTick() {
        tickTask = Task { [weak self] in
            while true {
                try? await Task.sleep(for: .milliseconds(10))
                guard let self, !Task.isCancelled, self.state.isRunning else { return }
                self.emit(TimerState(elapsed: self.state.elapsed + 0.01, isRunning: true))
            }
        }
    }
}
