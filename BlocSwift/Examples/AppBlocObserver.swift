//
//  AppBlocObserver.swift
//  BlocSwift
//

import Bloc
import Foundation

#if DEBUG
import Pulse

/// The application-wide Bloc observer that routes all lifecycle events to Pulse.
///
/// Set as the global observer once at app startup — every Bloc is then logged
/// automatically with no per-Bloc boilerplate:
///
/// ```swift
/// BlocObserver.shared = AppBlocObserver()
/// ```
///
/// All log entries use the `"bloc"` label in Pulse, making it easy to filter
/// Bloc activity in the console.
@MainActor
final class AppBlocObserver: BlocObserver {

    private let label = "bloc"

    // Fires for both Blocs and Cubits
    override func onCreate(_ emitter: any StateEmitter) {
        super.onCreate(emitter)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .notice,
            message: "🚀 \(type(of: emitter)) initialized",
            metadata: [
                "blocName": .string("\(type(of: emitter))"),
                "initialState": .string("\(emitter.state)")
            ]
        )
    }

    // Bloc-only
    override func onEvent(_ bloc: any BlocBase, event: Any) {
        super.onEvent(bloc, event: event)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .debug,
            message: "📨 \(type(of: bloc)) received: \(event)",
            metadata: [
                "blocName": .string("\(type(of: bloc))"),
                "eventType": .string("\(type(of: event))"),
                "event": .string("\(event)")
            ]
        )
    }

    // Fires for both Blocs and Cubits
    override func onChange(_ emitter: any StateEmitter, change: Any) {
        super.onChange(emitter, change: change)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .info,
            message: "🔄 \(type(of: emitter)): \(change)",
            metadata: [
                "blocName": .string("\(type(of: emitter))"),
                "change": .string("\(change)")
            ]
        )
    }

    // Bloc-only
    override func onTransition(_ bloc: any BlocBase, transition: Any) {
        super.onTransition(bloc, transition: transition)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .info,
            message: "➡️ \(type(of: bloc)): \(transition)",
            metadata: [
                "blocName": .string("\(type(of: bloc))"),
                "transition": .string("\(transition)")
            ]
        )
    }

    // Fires for both Blocs and Cubits
    override func onError(_ emitter: any StateEmitter, error: Error) {
        super.onError(emitter, error: error)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .error,
            message: "❌ \(type(of: emitter)): \(error.localizedDescription)",
            metadata: [
                "blocName": .string("\(type(of: emitter))"),
                "errorType": .string("\(type(of: error))"),
                "errorDescription": .string(error.localizedDescription)
            ]
        )
    }

    // Fires for both Blocs and Cubits
    override func onClose(_ emitter: any StateEmitter) {
        super.onClose(emitter)
        LoggerStore.shared.storeMessage(
            label: label,
            level: .notice,
            message: "🔒 \(type(of: emitter)) closed",
            metadata: [
                "blocName": .string("\(type(of: emitter))")
            ]
        )
    }
}

#else

/// No-op observer for release builds.
@MainActor
final class AppBlocObserver: BlocObserver {}

#endif
