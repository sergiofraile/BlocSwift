//
//  Bloc.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Combine
import Foundation
import Observation

/// A predictable state management class that processes events and emits state changes.
///
/// `Bloc` is the core building block of the Bloc pattern. It receives ``BlocEvent``s,
/// processes them through registered handlers, and emits new ``BlocState``s that
/// SwiftUI automatically observes.
///
/// ## Overview
///
/// A Bloc encapsulates your business logic and manages state transitions in a predictable way.
/// You create a Bloc by subclassing and registering event handlers:
///
/// ```swift
/// @MainActor
/// class CounterBloc: Bloc<Int, CounterEvent> {
///
///     init() {
///         super.init(initialState: 0)
///
///         on(.increment) { [weak self] event, emit in
///             guard let self else { return }
///             emit(self.state + 1)
///         }
///
///         on(.decrement) { [weak self] event, emit in
///             guard let self else { return }
///             emit(self.state - 1)
///         }
///     }
/// }
/// ```
///
/// ## State Observation
///
/// Thanks to the `@Observable` macro, SwiftUI views automatically re-render when
/// the ``state`` property changes. No manual subscription is required:
///
/// ```swift
/// struct CounterView: View {
///     let counterBloc = BlocRegistry.resolve(CounterBloc.self)
///
///     var body: some View {
///         Text("Count: \(counterBloc.state)")  // Automatically updates
///         Button("+") { counterBloc.send(.increment) }
///     }
/// }
/// ```
///
/// ## Combine Integration
///
/// For advanced reactive patterns, subscribe to ``statePublisher``:
///
/// ```swift
/// counterBloc.statePublisher
///     .sink { state in
///         print("State changed: \(state)")
///     }
///     .store(in: &cancellables)
/// ```
///
/// ## Topics
///
/// ### Creating a Bloc
///
/// - ``init(initialState:)``
///
/// ### Accessing State
///
/// - ``state``
/// - ``statePublisher``
///
/// ### Handling Events
///
/// - ``on(_:handler:)``
/// - ``mapEventToState(event:emit:)``
/// - ``send(_:)``
///
/// ### Emitting State
///
/// - ``emit(_:)``
@Observable
@MainActor
open class Bloc<S: BlocState, E: BlocEvent>: BlocBase {
    
    /// The state type managed by this Bloc.
    public typealias State = S
    
    /// The event type processed by this Bloc.
    public typealias Event = E
    
    // MARK: - Observable State
    
    @ObservationIgnored
    private var _state: S
    
    /// The current state of the Bloc.
    ///
    /// This property is automatically observed by SwiftUI. When you access it
    /// in a view's `body`, SwiftUI registers a dependency and re-renders the
    /// view when the state changes.
    ///
    /// ```swift
    /// Text("Count: \(counterBloc.state)")  // View updates when state changes
    /// ```
    ///
    /// - Note: This property is read-only from outside the Bloc. Use ``emit(_:)``
    ///   to update state from within event handlers.
    public var state: S {
        get {
            access(keyPath: \.state)
            return _state
        }
        set {
            withMutation(keyPath: \.state) {
                _state = newValue
            }
        }
    }
    
    // MARK: - Combine Support
    
    @ObservationIgnored
    private var statesSubject: CurrentValueSubject<S, Never>
    
    /// A Combine publisher that emits state changes.
    ///
    /// Use this publisher for advanced reactive patterns or when you need
    /// to integrate with existing Combine pipelines:
    ///
    /// ```swift
    /// counterBloc.statePublisher
    ///     .removeDuplicates()
    ///     .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    ///     .sink { state in
    ///         print("Debounced state: \(state)")
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Note: For SwiftUI views, prefer accessing ``state`` directly—it's
    ///   simpler and automatically handles observation.
    public var statePublisher: AnyPublisher<S, Never> {
        statesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Events
    
    @ObservationIgnored
    private var eventSubject = PassthroughSubject<Event, Never>()
    
    @ObservationIgnored
    private var errorSubject = PassthroughSubject<Error, Never>()
    
    /// A Combine publisher that emits every event dispatched to the Bloc.
    ///
    /// Events are published after the Bloc has finished processing them,
    /// making this publisher useful for logging, analytics, or side-effect
    /// pipelines that react to events externally:
    ///
    /// ```swift
    /// counterBloc.eventsPublisher
    ///     .sink { event in
    ///         print("Event received: \(event)")
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public var eventsPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    /// A Combine publisher that emits errors signalled via ``addError(_:)``.
    ///
    /// Use this to observe Bloc errors without encoding them into the state type:
    ///
    /// ```swift
    /// counterBloc.errorsPublisher
    ///     .sink { error in
    ///         print("Bloc error: \(error)")
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public var errorsPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Handlers

    /// Bundles a handler closure with its associated event transformer.
    private struct RegisteredHandler {
        let handler: Handler
        let transformer: EventTransformer
    }

    /// Bundles a predicate-based handler closure with its transformer.
    ///
    /// Used by ``on(where:transformer:handler:)`` for events with associated
    /// values that cannot be matched by exact equality.
    private struct PatternHandler {
        let id: UUID
        let matches: (E) -> Bool
        let handler: Handler
        let transformer: EventTransformer
    }

    @ObservationIgnored
    private var registeredHandlers: [E: RegisteredHandler] = [:]

    @ObservationIgnored
    private var patternHandlers: [PatternHandler] = []

    /// Tracks active Tasks for transformers that need lifecycle management
    /// (droppable, restartable, debounce, throttle).
    ///
    /// Keys are either an exact event value (`E`) or a `UUID` for pattern handlers,
    /// both wrapped in `AnyHashable`.
    @ObservationIgnored
    private var activeTasks: [AnyHashable: Task<Void, Never>] = [:]

    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()
    
    /// Whether this Bloc has been closed via ``close()``.
    ///
    /// Once `true`, ``send(_:)`` and ``emit(_:)`` are no-ops. Combine publishers
    /// have sent their completion signal.
    public private(set) var isClosed: Bool = false

    /// Holds the event being processed by ``send(_:)`` for the duration of its synchronous
    /// handler execution.
    ///
    /// This is the rendezvous point between ``send(_:)`` and ``emit(_:)``: because `emit` is
    /// called one stack frame *inside* the handler, it has no direct access to the event that
    /// triggered it. `send` deposits the event here before invoking the handler, and `emit`
    /// reads it to construct a ``Transition``. `send` clears it immediately after the handler
    /// returns, so the value is never retained beyond a single synchronous dispatch.
    ///
    /// When `emit` is called from an async `Task` context, `send` has already returned and
    /// cleared this property, so `currentEvent` is `nil`. In that case `emit` skips
    /// ``onTransition(_:)`` and only calls ``onChange(_:)``, which is the correct behaviour —
    /// the causal link between event and emission no longer holds across an async boundary.
    @ObservationIgnored
    private var currentEvent: E?
    
    // MARK: - Initialization
    
    /// Creates a new Bloc with the specified initial state.
    ///
    /// After initialization, register event handlers using ``on(_:handler:)``
    /// or override ``mapEventToState(event:emit:)`` for dynamic event handling.
    ///
    /// ```swift
    /// @MainActor
    /// class CounterBloc: Bloc<Int, CounterEvent> {
    ///
    ///     init() {
    ///         super.init(initialState: 0)
    ///
    ///         on(.increment) { [weak self] event, emit in
    ///             guard let self else { return }
    ///             emit(self.state + 1)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter initialState: The starting state for the Bloc.
    public init(initialState: State) {
        _state = initialState
        statesSubject = CurrentValueSubject<S, Never>(initialState)
        BlocObserver.shared.onCreate(self)
    }
    
    // MARK: - State Emission
    
    /// Emits a new state, triggering UI updates and lifecycle hooks.
    ///
    /// Call this method from within event handlers to transition to a new state.
    /// This updates both the observable ``state`` property and the ``statePublisher``.
    ///
    /// ```swift
    /// on(.increment) { [weak self] event, emit in
    ///     guard let self else { return }
    ///     emit(self.state + 1)
    /// }
    /// ```
    ///
    /// You can also call `emit` directly on the Bloc instance for async operations:
    ///
    /// ```swift
    /// Task {
    ///     let data = try await api.fetchData()
    ///     self.emit(.loaded(data))
    /// }
    /// ```
    ///
    /// ## Lifecycle hooks
    ///
    /// Every call to `emit` triggers the following hooks in order:
    ///
    /// 1. **``onTransition(_:)``** — fired first, but only when `emit` is called
    ///    synchronously within an event handler (i.e. not from inside a `Task`).
    ///    Carries the triggering event alongside the previous and next state.
    ///
    /// 2. **``onChange(_:)``** — fired after every `emit`, regardless of whether
    ///    the call is synchronous or async. Carries only the previous and next state.
    ///
    /// If you do not override either hook, both degenerate to no-ops and the
    /// overhead is negligible — `Change` and `Transition` are stack-allocated structs.
    ///
    /// - Parameter state: The new state to emit.
    public func emit(_ state: State) {
        guard !isClosed else { return }
        let change = Change(currentState: self.state, nextState: state)
        if let event = currentEvent {
            onTransition(Transition(currentState: self.state, event: event, nextState: state))
        }
        self.state = state
        statesSubject.send(state)
        onChange(change)
    }
    
    // MARK: - Event Handling
    
    /// Registers a handler for a specific event, with an optional transformer that controls
    /// how the handler is invoked when events arrive rapidly.
    ///
    /// Use this method to define how the Bloc responds to events. The handler
    /// receives the event and an `emit` function to output new states.
    ///
    /// ```swift
    /// // Default sequential transformer — existing behaviour
    /// on(.increment) { [weak self] event, emit in
    ///     guard let self else { return }
    ///     emit(self.state + 1)
    /// }
    ///
    /// // Only allow one refresh at a time — drop while active
    /// on(.refresh, transformer: .droppable) { event, emit in
    ///     Task { await refresh(emit: emit) }
    /// }
    /// ```
    ///
    /// - Important: Always use `[weak self]` in handlers that capture `self`
    ///   to avoid retain cycles.
    ///
    /// - Parameters:
    ///   - event: The specific event value to handle. Events must match by equality.
    ///     For events with associated values, use ``on(where:transformer:handler:)`` instead.
    ///   - transformer: Controls event processing strategy. Defaults to ``EventTransformer/sequential``.
    ///   - handler: A closure that processes the event and emits new states.
    public func on(_ event: E, transformer: EventTransformer = .sequential, handler: @escaping Handler) {
        registeredHandlers[event] = RegisteredHandler(handler: handler, transformer: transformer)
    }

    /// Registers a handler for events that match a predicate, with an optional transformer.
    ///
    /// Use this overload when the event has associated values — for example `search(query:)` —
    /// where each event value is unique and cannot be matched with simple equality:
    ///
    /// ```swift
    /// // Debounce every search event, regardless of its query value
    /// on(where: { if case .search = $0 { return true }; return false },
    ///    transformer: .debounce(.milliseconds(300))) { event, emit in
    ///     if case .search(let query) = event {
    ///         Task { await searchCards(query: query, emit: emit) }
    ///     }
    /// }
    /// ```
    ///
    /// Pattern handlers are evaluated in registration order. The first match wins.
    ///
    /// - Parameters:
    ///   - matches: A predicate that returns `true` for events this handler should process.
    ///   - transformer: Controls event processing strategy. Defaults to ``EventTransformer/sequential``.
    ///   - handler: A closure that processes the event and emits new states.
    public func on(where matches: @escaping (E) -> Bool, transformer: EventTransformer = .sequential, handler: @escaping Handler) {
        patternHandlers.append(PatternHandler(id: UUID(), matches: matches, handler: handler, transformer: transformer))
    }
    
    /// Override this method for custom or dynamic event-to-state mapping.
    ///
    /// Use `mapEventToState` when you need to handle events with associated
    /// values or when you prefer a switch-based approach:
    ///
    /// ```swift
    /// override func mapEventToState(event: SearchEvent, emit: @escaping Emitter) {
    ///     switch event {
    ///     case .queryChanged(let query):
    ///         var newState = state
    ///         newState.query = query
    ///         emit(newState)
    ///
    ///     case .search:
    ///         emit(SearchState(isLoading: true))
    ///         Task { await performSearch() }
    ///
    ///     case .resultsLoaded(let results):
    ///         emit(SearchState(results: results))
    ///     }
    /// }
    /// ```
    ///
    /// - Note: This method is called only when no handler is registered for
    ///   the event via ``on(_:handler:)``.
    ///
    /// - Parameters:
    ///   - event: The event to process.
    ///   - emit: A closure to call with the new state.
    open func mapEventToState(event: E, emit: @escaping Emitter) {
        // Override in subclasses for custom event handling
        print("No handler found for event: \(event)")
    }
    
    /// Signals that an error has occurred inside the Bloc.
    ///
    /// The error is broadcast on ``errorsPublisher`` so observers can react
    /// without encoding error state into the state type. Use this inside
    /// event handlers to surface non-fatal or out-of-band errors:
    ///
    /// ```swift
    /// on(.fetchData) { [weak self] event, emit in
    ///     guard let self else { return }
    ///     do {
    ///         let data = try await api.fetchData()
    ///         emit(.loaded(data))
    ///     } catch {
    ///         addError(error)   // broadcast without changing state
    ///         emit(.idle)
    ///     }
    /// }
    /// ```
    ///
    /// Observe errors via Combine:
    ///
    /// ```swift
    /// bloc.errorsPublisher
    ///     .sink { error in crashReporter.log(error) }
    ///     .store(in: &cancellables)
    /// ```
    ///
    /// - Parameter error: The error that occurred.
    public func addError(_ error: Error) {
        errorSubject.send(error)
        onError(error)
    }
    
    /// Sends an event to the Bloc for processing.
    ///
    /// This is the primary way to trigger state changes from your UI:
    ///
    /// ```swift
    /// Button("+") {
    ///     counterBloc.send(.increment)
    /// }
    /// ```
    ///
    /// The event is dispatched according to the transformer registered with
    /// ``on(_:transformer:handler:)``. The default ``EventTransformer/sequential``
    /// transformer processes events synchronously and immediately.
    ///
    /// - Parameter event: The event to send.
    public func send(_ event: E) {
        guard !isClosed else { return }
        onEvent(event)

        if let registered = registeredHandlers[event] {
            dispatch(event: event, key: AnyHashable(event), handler: registered.handler, transformer: registered.transformer)
        } else if let pattern = patternHandlers.first(where: { $0.matches(event) }) {
            dispatch(event: event, key: AnyHashable(pattern.id), handler: pattern.handler, transformer: pattern.transformer)
        } else {
            // Fall back to mapEventToState (always sequential / synchronous)
            currentEvent = event
            mapEventToState(event: event, emit: emit)
            currentEvent = nil
        }

        eventSubject.send(event)
    }

    /// Executes `handler` for `event` according to the given `transformer` strategy.
    ///
    /// - Parameters:
    ///   - event: The event being dispatched.
    ///   - key: Stable `AnyHashable` key used to track the active `Task` for this
    ///     event slot (exact-value events use the event itself; pattern handlers use
    ///     their registration `UUID`).
    ///   - handler: The handler closure to invoke.
    ///   - transformer: Governs when and how `handler` is invoked.
    private func dispatch(event: E, key: AnyHashable, handler: @escaping Handler, transformer: EventTransformer) {
        switch transformer.strategy {

        case .sequential:
            // Synchronous dispatch — preserves onTransition firing.
            currentEvent = event
            handler(event, emit)
            currentEvent = nil

        case .concurrent:
            // Each event gets its own Task; no coordination between them.
            Task { [weak self] in
                guard let self else { return }
                handler(event, self.emit)
            }

        case .droppable:
            // Silently ignore the event while a Task for this slot is running.
            guard activeTasks[key] == nil else { return }
            activeTasks[key] = Task { [weak self, key] in
                guard let self else { return }
                handler(event, self.emit)
                self.activeTasks[key] = nil
            }

        case .restartable:
            // Cancel any pending Task for this slot before starting a new one.
            activeTasks[key]?.cancel()
            activeTasks[key] = Task { [weak self, key] in
                guard let self, !Task.isCancelled else { return }
                handler(event, self.emit)
                self.activeTasks[key] = nil
            }

        case .debounce(let duration):
            // Cancel the pending timer and restart it. Handler fires only after
            // `duration` elapses without a new event arriving.
            activeTasks[key]?.cancel()
            activeTasks[key] = Task { [weak self, key] in
                guard let self else { return }
                do {
                    try await Task.sleep(for: duration)
                    handler(event, self.emit)
                } catch {
                    // Task was cancelled before the debounce period elapsed.
                }
                self.activeTasks[key] = nil
            }

        case .throttle(let duration):
            // Fire immediately, then ignore events for `duration`.
            guard activeTasks[key] == nil else { return }
            currentEvent = event
            handler(event, emit)
            currentEvent = nil
            activeTasks[key] = Task { [weak self, key] in
                guard let self else { return }
                try? await Task.sleep(for: duration)
                self.activeTasks[key] = nil
            }
        }
    }
    
    // MARK: - Lifecycle Hooks
    
    /// Called immediately before an event is processed.
    ///
    /// Override to react to incoming events at the Bloc level:
    ///
    /// ```swift
    /// override func onEvent(_ event: CounterEvent) {
    ///     super.onEvent(event)
    ///     print("Processing event: \(event)")
    /// }
    /// ```
    ///
    /// - Parameter event: The event about to be dispatched.
    open func onEvent(_ event: E) {
        BlocObserver.shared.onEvent(self, event: event)
    }
    
    /// Called after every ``emit(_:)``, with the previous and next state.
    ///
    /// `onChange` fires for all state changes, including those emitted
    /// asynchronously from within a `Task`:
    ///
    /// ```swift
    /// override func onChange(_ change: Change<MyState>) {
    ///     super.onChange(change)
    ///     print(change)
    ///     // Change { currentState: idle, nextState: loading }
    /// }
    /// ```
    ///
    /// - Parameter change: A value containing `currentState` and `nextState`.
    open func onChange(_ change: Change<S>) {
        BlocObserver.shared.onChange(self, change: change)
    }
    
    /// Called after synchronous ``emit(_:)`` calls that occur within an event handler.
    ///
    /// `onTransition` extends ``onChange(_:)`` by also capturing the event that
    /// caused the state change. It only fires when `emit` is called synchronously
    /// during handler execution — it will **not** fire for emissions made from
    /// inside a `Task` (use ``onChange(_:)`` for those):
    ///
    /// ```swift
    /// override func onTransition(_ transition: Transition<CounterEvent, Int>) {
    ///     super.onTransition(transition)
    ///     print(transition)
    ///     // Transition { currentState: 0, event: increment, nextState: 1 }
    /// }
    /// ```
    ///
    /// - Parameter transition: A value containing `currentState`, `event`, and `nextState`.
    open func onTransition(_ transition: Transition<E, S>) {
        BlocObserver.shared.onTransition(self, transition: transition)
    }
    
    /// Called when ``addError(_:)`` is invoked.
    ///
    /// Override to handle errors at the Bloc level, for example to log them or
    /// emit a fallback state:
    ///
    /// ```swift
    /// override func onError(_ error: Error) {
    ///     super.onError(error)
    ///     print("Bloc error: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter error: The error that was signalled.
    open func onError(_ error: Error) {
        BlocObserver.shared.onError(self, error: error)
    }

    // MARK: - Lifecycle Management

    /// Closes the Bloc, releasing resources and completing all Combine publishers.
    ///
    /// Call `close()` when a Bloc is no longer needed — typically when its
    /// owning screen is dismissed. After calling `close()`:
    ///
    /// - ``send(_:)`` and ``emit(_:)`` become no-ops.
    /// - ``eventsPublisher``, ``errorsPublisher``, and ``statePublisher``
    ///   send their completion signal to subscribers.
    /// - ``onClose()`` fires, which in turn calls ``BlocObserver/onClose(_:)``.
    ///
    /// `close()` is idempotent — repeated calls are safe.
    ///
    /// ``BlocProvider`` calls `close()` automatically on all registered Blocs
    /// when the registry is deallocated (e.g. on app termination, or when a
    /// scoped `BlocProvider` leaves the view tree).
    public func close() {
        guard !isClosed else { return }
        isClosed = true
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        cancellables.removeAll()
        eventSubject.send(completion: .finished)
        errorSubject.send(completion: .finished)
        onClose()
    }

    /// Called once when ``close()`` is invoked on this Bloc.
    ///
    /// Override to perform custom teardown — release held resources, flush
    /// pending writes, or update UI to reflect the closed state:
    ///
    /// ```swift
    /// override func onClose() {
    ///     super.onClose()
    ///     print("\(type(of: self)) closed")
    /// }
    /// ```
    ///
    /// Always call `super.onClose()` so ``BlocObserver/onClose(_:)`` fires.
    open func onClose() {
        BlocObserver.shared.onClose(self)
    }
}
