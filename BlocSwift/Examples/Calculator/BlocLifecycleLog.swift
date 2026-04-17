//
//  BlocLifecycleLog.swift
//  BlocSwift
//

import Foundation
import Observation
import SwiftUI

/// An observable store for lifecycle hook entries produced by ``CalculatorBloc``.
///
/// The view observes `entries` directly because `BlocLifecycleLog` is `@Observable`.
/// As the user interacts with the calculator, new entries appear in real time,
/// making each Bloc lifecycle hook visible.
@Observable
@MainActor
final class BlocLifecycleLog {

    var entries: [LogEntry] = []

    func append(kind: LogEntry.Kind, message: String) {
        entries.append(LogEntry(timestamp: .now, kind: kind, message: message))
        if entries.count > 200 { entries.removeFirst() }
    }

    func clear() { entries.removeAll() }

    // MARK: - Entry

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let kind: Kind
        let message: String

        enum Kind {
            case event, change, transition, error, close

            var label: String {
                switch self {
                case .event:      return "EVENT"
                case .change:     return "CHANGE"
                case .transition: return "TRANSITION"
                case .error:      return "ERROR"
                case .close:      return "CLOSE"
                }
            }

            var color: Color {
                switch self {
                case .event:      return .green
                case .change:     return .cyan
                case .transition: return .purple
                case .error:      return .red
                case .close:      return .orange
                }
            }

            var symbol: String {
                switch self {
                case .event:      return "arrow.right.circle"
                case .change:     return "arrow.left.arrow.right"
                case .transition: return "arrow.triangle.swap"
                case .error:      return "exclamationmark.triangle"
                case .close:      return "xmark.circle"
                }
            }
        }
    }
}

// MARK: - Timestamp Formatting

extension Date {
    var logTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: self)
    }
}
