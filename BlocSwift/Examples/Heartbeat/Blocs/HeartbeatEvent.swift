//
//  HeartbeatEvent.swift
//  BlocSwift
//

import Bloc

/// Events for the Heartbeat example.
///
/// `.tick` is sent internally every second by the Bloc's async ticker task.
/// Users of the Bloc only send `.start` and `.newSession`.
enum HeartbeatEvent: BlocEvent {
    /// Begin the heartbeat ticker.
    case start
    /// Emitted internally each second by the async ticker task.
    case tick
    /// Close the current Bloc, create a fresh one, and start immediately.
    case newSession
}
