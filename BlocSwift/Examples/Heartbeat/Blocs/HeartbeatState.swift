//
//  HeartbeatState.swift
//  BlocSwift
//

import Bloc

/// State for the Heartbeat example.
struct HeartbeatState: BlocState {
    /// Number of one-second ticks since the session started.
    var tickCount: Int
    /// Whether the ticker is currently running.
    var isRunning: Bool

    static let initial = HeartbeatState(tickCount: 0, isRunning: false)

    /// Session duration formatted as MM:SS derived from `tickCount`.
    var formattedDuration: String {
        let m = tickCount / 60
        let s = tickCount % 60
        return String(format: "%02d:%02d", m, s)
    }
}
