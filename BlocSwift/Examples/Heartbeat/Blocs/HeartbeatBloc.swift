//
//  HeartbeatBloc.swift
//  BlocSwift
//

import Bloc
import Foundation

/// A Bloc that runs an async one-second ticker to demonstrate **scoped lifecycle management**.
///
/// ## Why this example exists
///
/// Most Blocs in this app are registered once in `BlocProvider` and live for the
/// entire app session. `HeartbeatBloc` is different — it is **not** registered in
/// `BlocProvider`. Instead, the `HeartbeatView` creates it directly using `@State`
/// and calls `close()` in `.onDisappear`. This is the correct pattern for Blocs
/// that are scoped to a single screen or sheet.
///
/// ## What to watch
///
/// 1. Navigate to **Heartbeat** → `onCreate` fires, the ticker starts.
/// 2. Watch ticks accumulate in the lifecycle log every second.
/// 3. Navigate away → `onDisappear` fires `close()` → `onClose` fires and the
///    async ticker task is cancelled immediately.
/// 4. Return → a brand-new `HeartbeatBloc` is created, starting from zero.
///
/// ## Async task cancellation
///
/// The ticker is a `Task` stored in `tickerTask`. `close()` cancels it explicitly
/// via `onClose()`, so the task stops the moment `close()` is called rather than
/// waiting for the next `isClosed` check in the loop.
@MainActor
class HeartbeatBloc: Bloc<HeartbeatState, HeartbeatEvent> {

    // MARK: - Lifecycle Log

    /// Observable log of every lifecycle hook invocation.
    /// `HeartbeatView` observes this directly to show Bloc internals in real time.
    let lifecycleLog = BlocLifecycleLog()

    // MARK: - Internal ticker

    /// The async task that sends `.tick` every second.
    /// Stored so `onClose()` can cancel it immediately rather than waiting for
    /// the next loop iteration.
    private var tickerTask: Task<Void, Never>?

    // MARK: - Init

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

    // MARK: - Lifecycle Hooks

    override func onEvent(_ event: HeartbeatEvent) {
        super.onEvent(event)
        switch event {
        case .start:
            lifecycleLog.append(kind: .event, message: "start — ticker launched")
        case .tick:
            lifecycleLog.append(kind: .event, message: "tick #\(state.tickCount + 1)")
        case .newSession:
            break
        }
    }

    override func onChange(_ change: Change<HeartbeatState>) {
        super.onChange(change)
        if change.nextState.tickCount == 0 {
            lifecycleLog.append(kind: .change, message: "session started")
        } else {
            lifecycleLog.append(
                kind: .change,
                message: "\(change.currentState.formattedDuration) → \(change.nextState.formattedDuration)"
            )
        }
    }

    override func onClose() {
        super.onClose()
        tickerTask?.cancel()
        tickerTask = nil
        lifecycleLog.append(
            kind: .close,
            message: "Bloc closed after \(state.tickCount) tick\(state.tickCount == 1 ? "" : "s") — ticker cancelled"
        )
    }
}
