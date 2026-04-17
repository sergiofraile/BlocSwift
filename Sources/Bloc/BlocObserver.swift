//
//  BlocObserver.swift
//  Bloc
//
//  Created by Sergio Fraile on 04/03/2026.
//

/// A global observer that receives lifecycle notifications from every ``Bloc``
/// and ``Cubit`` in the application.
///
/// `BlocObserver` is the recommended way to implement cross-cutting concerns such
/// as logging, analytics, crash reporting, and debugging. Set a custom observer
/// once at app startup and it automatically applies to every Bloc and Cubit without
/// any changes to individual subclasses:
///
/// ```swift
/// // In your App entry point
/// BlocObserver.shared = AppBlocObserver()
/// ```
///
/// ## Implementing a custom observer
///
/// Subclass `BlocObserver` and override the hooks you care about. Always call
/// `super` so the chain is preserved for future library features:
///
/// ```swift
/// class AppBlocObserver: BlocObserver {
///
///     // Fires for both Blocs and Cubits
///     override func onCreate(_ emitter: any StateEmitter) {
///         super.onCreate(emitter)
///         print("Created: \(type(of: emitter))")
///     }
///
///     // Bloc-only: fires when send(_:) is called
///     override func onEvent(_ bloc: any BlocBase, event: Any) {
///         super.onEvent(bloc, event: event)
///         print("\(type(of: bloc)) received: \(event)")
///     }
///
///     // Fires for both Blocs and Cubits after emit(_:)
///     override func onChange(_ emitter: any StateEmitter, change: Any) {
///         super.onChange(emitter, change: change)
///         print("\(type(of: emitter)) changed: \(change)")
///     }
///
///     // Bloc-only: synchronous emit inside an event handler
///     override func onTransition(_ bloc: any BlocBase, transition: Any) {
///         super.onTransition(bloc, transition: transition)
///         print("\(type(of: bloc)) transition: \(transition)")
///     }
///
///     // Fires for both Blocs and Cubits on addError(_:)
///     override func onError(_ emitter: any StateEmitter, error: Error) {
///         super.onError(emitter, error: error)
///         print("\(type(of: emitter)) error: \(error)")
///     }
/// }
/// ```
///
/// ## Parameter typing
///
/// - Hooks that apply to **both** Blocs and Cubits use `any StateEmitter`.
/// - Hooks that are **Bloc-only** (events, transitions) use `any BlocBase`.
/// - The `event`, `change`, and `transition` parameters are `Any` to keep the
///   observer non-generic. Cast to the concrete type when needed.
///
/// ## Topics
///
/// ### Setting the observer
///
/// - ``shared``
///
/// ### Lifecycle hooks (Bloc + Cubit)
///
/// - ``onCreate(_:)``
/// - ``onChange(_:change:)``
/// - ``onError(_:error:)``
/// - ``onClose(_:)``
///
/// ### Lifecycle hooks (Bloc only)
///
/// - ``onEvent(_:event:)``
/// - ``onTransition(_:transition:)``
@MainActor
open class BlocObserver {

    /// The global observer instance, called by every ``Bloc`` and ``Cubit``
    /// at each lifecycle point.
    ///
    /// Replace with a custom subclass at app startup before any Blocs are created:
    ///
    /// ```swift
    /// @main
    /// struct MyApp: App {
    ///     init() {
    ///         BlocObserver.shared = AppBlocObserver()
    ///     }
    /// }
    /// ```
    /// - Note: Marked `nonisolated(unsafe)` because the compiler cannot verify that
    ///   writes and reads are actor-isolated. In practice this is safe: `shared` is
    ///   written exactly once at app startup (before any Bloc is created) and is only
    ///   ever read from `@MainActor` context inside Bloc lifecycle hooks.
    nonisolated(unsafe) public static var shared: BlocObserver = BlocObserver()

    nonisolated public init() {}

    // MARK: - Lifecycle Hooks (Bloc + Cubit)

    /// Called when a Bloc or Cubit is initialised.
    ///
    /// - Parameter emitter: The ``StateEmitter`` that was created.
    open func onCreate(_ emitter: any StateEmitter) {}

    /// Called after every ``Bloc/emit(_:)`` or ``Cubit/emit(_:)``, with before/after states.
    ///
    /// - Parameters:
    ///   - emitter: The ``StateEmitter`` that emitted a new state.
    ///   - change: A ``Change`` value, typed as `Any`. Cast to `Change<SomeState>` if needed.
    open func onChange(_ emitter: any StateEmitter, change: Any) {}

    /// Called when ``Bloc/addError(_:)`` or ``Cubit/addError(_:)`` is invoked.
    ///
    /// - Parameters:
    ///   - emitter: The ``StateEmitter`` that signalled the error.
    ///   - error: The error that was reported.
    open func onError(_ emitter: any StateEmitter, error: Error) {}

    /// Called when ``Bloc/close()`` or ``Cubit/close()`` is invoked.
    ///
    /// - Parameter emitter: The ``StateEmitter`` that was closed.
    open func onClose(_ emitter: any StateEmitter) {}

    // MARK: - Lifecycle Hooks (Bloc only)

    /// Called immediately before an event is processed by a Bloc.
    ///
    /// This hook is **not** called for Cubits (which have no events).
    ///
    /// - Parameters:
    ///   - bloc: The Bloc receiving the event.
    ///   - event: The event, typed as `Any`. Cast to the concrete event type if needed.
    open func onEvent(_ bloc: any BlocBase, event: Any) {}

    /// Called for synchronous state changes, with the event that caused them.
    ///
    /// Only fires when `emit` is called synchronously inside a Bloc event handler.
    /// Async emissions (inside `Task`) reach ``onChange(_:change:)`` only.
    /// This hook is **not** called for Cubits.
    ///
    /// - Parameters:
    ///   - bloc: The Bloc whose state transitioned.
    ///   - transition: A ``Transition`` value, typed as `Any`.
    open func onTransition(_ bloc: any BlocBase, transition: Any) {}
}
