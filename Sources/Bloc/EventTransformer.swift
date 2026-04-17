//
//  EventTransformer.swift
//  Bloc
//

/// Controls how events are processed when a new event of the same type arrives
/// while a previous handler invocation is still pending or active.
///
/// Attach a transformer when registering an event handler via ``Bloc/on(_:transformer:handler:)``:
///
/// ```swift
/// // Only fire the search handler after 300 ms of silence
/// on(.search, transformer: .debounce(.milliseconds(300))) { event, emit in
///     performSearch()
/// }
///
/// // Cancel a previous load and restart with the newest event
/// on(.load, transformer: .restartable) { event, emit in
///     Task { await load(emit: emit) }
/// }
/// ```
///
/// ## Built-in transformers
///
/// | Transformer | Behaviour |
/// |-------------|-----------|
/// | ``sequential`` | Default. Calls handlers one at a time, in order. |
/// | ``concurrent`` | Runs each handler in its own `Task`, all in parallel. |
/// | ``droppable`` | Ignores new events while the previous handler task is active. |
/// | ``restartable`` | Cancels the active handler task and restarts with the new event. |
/// | ``debounce(_:)`` | Waits for a quiet period before invoking; each new event resets the timer. |
/// | ``throttle(_:)`` | Calls the handler immediately, then ignores events for the duration. |
public struct EventTransformer: Sendable {

    // MARK: - Internal strategy

    enum Strategy: Sendable {
        case sequential
        case concurrent
        case droppable
        case restartable
        case debounce(Duration)
        case throttle(Duration)
    }

    let strategy: Strategy

    private init(strategy: Strategy) {
        self.strategy = strategy
    }

    // MARK: - Static transformers

    /// Processes events one at a time, in the order received.
    ///
    /// This is the default. It preserves the current synchronous dispatch
    /// behaviour: the handler is called directly inside ``Bloc/send(_:)``,
    /// so ``Bloc/onTransition(_:)`` fires correctly for synchronous `emit` calls.
    public static let sequential = EventTransformer(strategy: .sequential)

    /// Runs every handler invocation in its own `Task`, all in parallel.
    ///
    /// Use `concurrent` when events are independent and the handler completes
    /// quickly. Handlers run on `@MainActor`, so state updates are still
    /// thread-safe, but two handlers may overlap.
    public static let concurrent = EventTransformer(strategy: .concurrent)

    /// Ignores new events while the previous handler `Task` is still active.
    ///
    /// Useful when an event triggers expensive work (e.g. a network request)
    /// and repeated rapid taps should be silently dropped until the first
    /// invocation finishes.
    public static let droppable = EventTransformer(strategy: .droppable)

    /// Cancels the active handler `Task` and restarts with the incoming event.
    ///
    /// Useful for "load latest" patterns where only the most recent event
    /// matters. The previous task is cancelled; if it is sleeping (e.g. with
    /// `Task.sleep`) the cancellation takes effect immediately at the sleep
    /// point. Note that unstructured child tasks spawned inside the handler
    /// are not automatically cancelled.
    public static let restartable = EventTransformer(strategy: .restartable)

    /// Waits for `duration` of silence before invoking the handler.
    ///
    /// Every time a new event arrives the pending timer is cancelled and
    /// restarted. The handler is only called once the stream of events pauses
    /// for at least `duration`.
    ///
    /// Typical use-case: live search — debounce user keystrokes so that the
    /// network call fires only after the user stops typing:
    ///
    /// ```swift
    /// on(where: { if case .search = $0 { return true }; return false },
    ///    transformer: .debounce(.milliseconds(300))) { event, emit in
    ///     if case .search(let query) = event {
    ///         Task { await searchCards(query: query, emit: emit) }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter duration: Minimum quiet period before the handler fires.
    public static func debounce(_ duration: Duration) -> EventTransformer {
        EventTransformer(strategy: .debounce(duration))
    }

    /// Calls the handler immediately, then suppresses further events for `duration`.
    ///
    /// Unlike `debounce`, `throttle` fires on the *leading* edge: the first
    /// event is processed right away, and subsequent events within the
    /// throttle window are ignored.
    ///
    /// ```swift
    /// on(.refresh, transformer: .throttle(.seconds(2))) { event, emit in
    ///     Task { await refresh(emit: emit) }
    /// }
    /// ```
    ///
    /// - Parameter duration: Suppression window after the handler fires.
    public static func throttle(_ duration: Duration) -> EventTransformer {
        EventTransformer(strategy: .throttle(duration))
    }
}
