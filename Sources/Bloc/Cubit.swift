//
//  Cubit.swift
//  Bloc
//

import Combine
import Observation

/// A lightweight state-management class that exposes direct methods instead of events.
///
/// `Cubit` is the simpler sibling of ``Bloc``. Rather than dispatching events through
/// a handler registry, you call methods on the Cubit directly. The Cubit calls
/// ``emit(_:)`` internally to update state.
///
/// ## When to use Cubit vs Bloc
///
/// | | Cubit | Bloc |
/// |---|---|---|
/// | API style | Direct method calls | Dispatched events |
/// | Audit trail | No event log | Full event history |
/// | Transformers | Not needed | `.debounce`, `.restartable`, … |
/// | Best for | Simple, well-understood logic | Complex flows, analytics, testability |
///
/// ## Basic Usage
///
/// ```swift
/// @MainActor
/// class CounterCubit: Cubit<Int> {
///
///     init() { super.init(initialState: 0) }
///
///     func increment() { emit(state + 1) }
///     func decrement() { emit(state - 1) }
///     func reset()     { emit(0) }
/// }
/// ```
///
/// ```swift
/// struct CounterView: View {
///     let cubit = BlocRegistry.resolve(CounterCubit.self)
///
///     var body: some View {
///         Text("\(cubit.state)")
///         Button("+") { cubit.increment() }
///     }
/// }
/// ```
///
/// ## Lifecycle Hooks
///
/// Override the protected hooks to add logging or side effects:
///
/// ```swift
/// override func onChange(_ change: Change<Int>) {
///     super.onChange(change)
///     print("Counter changed: \(change.currentState) → \(change.nextState)")
/// }
///
/// override func onError(_ error: Error) {
///     super.onError(error)
///     print("Error: \(error)")
/// }
/// ```
///
/// ## BlocObserver Integration
///
/// All lifecycle events are automatically forwarded to the global
/// ``BlocObserver``. The ``BlocObserver/onEvent(_:event:)`` and
/// ``BlocObserver/onTransition(_:transition:)`` hooks are Bloc-only
/// and are **not** fired for Cubits.
///
/// ## Topics
///
/// ### Creating a Cubit
///
/// - ``init(initialState:)``
///
/// ### Accessing State
///
/// - ``state``
/// - ``statePublisher``
///
/// ### Emitting State
///
/// - ``emit(_:)``
///
/// ### Error Signalling
///
/// - ``addError(_:)``
/// - ``errorsPublisher``
///
/// ### Lifecycle
///
/// - ``close()``
/// - ``isClosed``
/// - ``onChange(_:)``
/// - ``onError(_:)``
/// - ``onClose()``
@Observable
@MainActor
open class Cubit<S: BlocState>: StateEmitter {

    /// The state type managed by this Cubit.
    public typealias State = S

    // MARK: - Observable State

    @ObservationIgnored
    private var _state: S

    /// The current state of the Cubit.
    ///
    /// This property is automatically observed by SwiftUI. Access it inside a
    /// view's `body` and SwiftUI re-renders the view whenever the state changes.
    ///
    /// ```swift
    /// Text("Elapsed: \(timerCubit.state.displayTime)")
    /// ```
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

    @ObservationIgnored
    private var errorSubject = PassthroughSubject<Error, Never>()

    /// A Combine publisher that emits every state change.
    public var statePublisher: AnyPublisher<S, Never> {
        statesSubject.eraseToAnyPublisher()
    }

    /// A Combine publisher that emits errors signalled via ``addError(_:)``.
    public var errorsPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Lifecycle State

    /// Whether ``close()`` has been called on this Cubit.
    ///
    /// Once `true`, ``emit(_:)`` and ``addError(_:)`` are no-ops and all
    /// Combine publishers have sent their completion signal.
    public private(set) var isClosed = false

    // MARK: - Initialization

    /// Creates a new Cubit with the specified initial state.
    ///
    /// Register any async work or subscriptions after calling `super.init`:
    ///
    /// ```swift
    /// @MainActor
    /// class TimerCubit: Cubit<TimerState> {
    ///     init() {
    ///         super.init(initialState: TimerState(elapsed: 0, isRunning: false))
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter initialState: The starting state for the Cubit.
    public init(initialState: S) {
        _state = initialState
        statesSubject = CurrentValueSubject<S, Never>(initialState)
        BlocObserver.shared.onCreate(self)
    }

    // MARK: - State Emission

    /// Emits a new state, triggering UI updates and lifecycle hooks.
    ///
    /// Call this from your Cubit's public methods to transition state:
    ///
    /// ```swift
    /// func increment() { emit(state + 1) }
    /// ```
    ///
    /// Emitting the same value as the current state is allowed; the hooks
    /// still fire because ``BlocState`` only requires `Equatable`, and the
    /// policy of whether to suppress equal emissions belongs to the observer.
    ///
    /// - Parameter state: The new state to emit.
    public func emit(_ state: S) {
        guard !isClosed else { return }
        let change = Change(currentState: self.state, nextState: state)
        self.state = state
        statesSubject.send(state)
        onChange(change)
    }

    // MARK: - Error Signalling

    /// Signals that an error has occurred without encoding it into the state type.
    ///
    /// The error is broadcast on ``errorsPublisher`` and forwarded to the global
    /// ``BlocObserver``. Use this for non-fatal, out-of-band errors:
    ///
    /// ```swift
    /// func loadData() async {
    ///     do {
    ///         let data = try await api.fetch()
    ///         emit(.loaded(data))
    ///     } catch {
    ///         addError(error)
    ///         emit(.idle)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter error: The error to signal.
    public func addError(_ error: Error) {
        errorSubject.send(error)
        onError(error)
    }

    // MARK: - Lifecycle Management

    /// Closes the Cubit, releasing resources and completing all Combine publishers.
    ///
    /// After `close()` returns:
    ///
    /// - ``emit(_:)`` and ``addError(_:)`` become no-ops.
    /// - ``statePublisher`` and ``errorsPublisher`` send their completion signal.
    /// - ``onClose()`` fires, which in turn notifies the global ``BlocObserver``.
    ///
    /// `close()` is idempotent — repeated calls are safe.
    ///
    /// ``BlocProvider`` calls this automatically when its registry is deallocated.
    /// For scoped Cubits, call it in `.onDisappear`:
    ///
    /// ```swift
    /// .onDisappear {
    ///     BlocRegistry.resolve(TimerCubit.self).close()
    /// }
    /// ```
    public func close() {
        guard !isClosed else { return }
        isClosed = true
        statesSubject.send(completion: .finished)
        errorSubject.send(completion: .finished)
        onClose()
    }

    // MARK: - Lifecycle Hooks

    /// Called after every ``emit(_:)`` with the previous and next state.
    ///
    /// Override to react to state changes at the Cubit level:
    ///
    /// ```swift
    /// override func onChange(_ change: Change<TimerState>) {
    ///     super.onChange(change)
    ///     print("\(change.currentState.displayTime) → \(change.nextState.displayTime)")
    /// }
    /// ```
    ///
    /// Always call `super.onChange(_:)` to ensure ``BlocObserver`` receives the event.
    ///
    /// - Parameter change: The previous and next state.
    open func onChange(_ change: Change<S>) {
        BlocObserver.shared.onChange(self, change: change)
    }

    /// Called when ``addError(_:)`` is invoked.
    ///
    /// Override to handle errors at the Cubit level:
    ///
    /// ```swift
    /// override func onError(_ error: Error) {
    ///     super.onError(error)
    ///     crashReporter.log(error)
    /// }
    /// ```
    ///
    /// Always call `super.onError(_:)` so ``BlocObserver`` receives the event.
    ///
    /// - Parameter error: The error that was signalled.
    open func onError(_ error: Error) {
        BlocObserver.shared.onError(self, error: error)
    }

    /// Called once when ``close()`` is invoked on this Cubit.
    ///
    /// Override to cancel async work or flush pending state:
    ///
    /// ```swift
    /// override func onClose() {
    ///     super.onClose()
    ///     tickTask?.cancel()
    /// }
    /// ```
    ///
    /// Always call `super.onClose()` so ``BlocObserver`` receives the event.
    open func onClose() {
        BlocObserver.shared.onClose(self)
    }
}
