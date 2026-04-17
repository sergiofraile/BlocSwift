//
//  TimerState.swift
//  BlocSwift
//

import Bloc

/// The state managed by ``TimerCubit``.
///
/// A single immutable value containing the elapsed time in seconds (with
/// centisecond precision) and whether the stopwatch is currently ticking.
struct TimerState: BlocState {

    /// Elapsed time in seconds. Centiseconds are represented as the fractional part.
    let elapsed: Double

    /// `true` while the stopwatch is actively counting.
    let isRunning: Bool

    // MARK: - Display Helpers

    /// Formatted as `MM:SS.cs` — suitable for a large display label.
    var displayTime: String {
        let totalCs = Int(elapsed * 100)
        let minutes     = totalCs / 6000
        let seconds     = (totalCs % 6000) / 100
        let centisecs   = totalCs % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centisecs)
    }

    /// Minutes component only — used for individual digit animations.
    var minutesDisplay: String { String(format: "%02d", Int(elapsed) / 60) }

    /// Seconds component only.
    var secondsDisplay: String { String(format: "%02d", Int(elapsed) % 60) }

    /// Centiseconds component only.
    var centisecondsDisplay: String { String(format: "%02d", Int(elapsed * 100) % 100) }
}
