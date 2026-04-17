//
//  BlocBase.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Combine

// MARK: - StateEmitter

/// The minimal protocol shared by both ``Bloc`` and ``Cubit``.
///
/// `StateEmitter` defines only what every state-managing object must provide:
/// observable state, a reactive state publisher, and the ability to be closed.
/// It is the storage type used by ``BlocRegistry`` and ``BlocProvider``, so
/// both Blocs and Cubits can be registered side-by-side.
///
/// You will rarely interact with `StateEmitter` directly. Use ``BlocBase`` when
/// you need event-driven behaviour, or ``Cubit`` when you want direct method
/// calls without events.
///
/// ## Topics
///
/// ### Associated Types
///
/// - ``State``
///
/// ### Accessing State
///
/// - ``state``
/// - ``statePublisher``
///
/// ### Lifecycle
///
/// - ``close()``
@MainActor
public protocol StateEmitter: AnyObject {

    /// The type of state managed by this emitter. Must conform to ``BlocState``.
    associatedtype State: BlocState

    /// The current state.
    var state: State { get }

    /// A Combine publisher that emits every state change.
    var statePublisher: AnyPublisher<State, Never> { get }

    /// Closes the emitter, releasing resources and completing all publishers.
    func close()
}

// MARK: - BlocBase

/// A protocol that defines the interface for all event-driven Bloc types.
///
/// `BlocBase` extends ``StateEmitter`` with the full event-processing API —
/// publishers, handlers, transformers, and error signalling. The ``Bloc`` class
/// provides the concrete implementation.
///
/// Use ``Cubit`` when you only need direct method calls without events. Use
/// `BlocBase` (via a `Bloc` subclass) when you need:
/// - An explicit event audit trail
/// - ``EventTransformer`` strategies (debounce, restartable, …)
/// - ``eventsPublisher`` / ``errorsPublisher`` Combine pipelines
///
/// ## Type Aliases
///
/// - ``Emitter``: `(State) -> Void` — call to emit a new state.
/// - ``Handler``: `(Event, Emitter) -> Void` — receives an event and the emitter.
///
/// ## Topics
///
/// ### Associated Types
///
/// - ``State``
/// - ``Event``
///
/// ### Handling Events
///
/// - ``on(_:handler:)``
/// - ``send(_:)``
@MainActor
public protocol BlocBase: StateEmitter {

    /// The type of events processed by this Bloc.
    associatedtype Event: BlocEvent

    /// A closure type for emitting new states from inside a handler.
    typealias Emitter = (State) -> Void

    /// A closure type for event handlers.
    typealias Handler = (Event, Emitter) -> Void

    /// A Combine publisher that emits every dispatched event, in order.
    var eventsPublisher: AnyPublisher<Event, Never> { get }

    /// A Combine publisher that emits errors signalled via ``addError(_:)``.
    var errorsPublisher: AnyPublisher<Error, Never> { get }

    /// Registers a handler for a specific event, with an optional transformer.
    func on(_ event: Event, transformer: EventTransformer, handler: @escaping Handler)

    /// Sends an event to the Bloc for processing.
    func send(_ event: Event)

    /// Signals an error without encoding it into the state type.
    func addError(_ error: Error)
}

// MARK: - Default parameter convenience

extension BlocBase {
    /// Convenience overload that uses the default ``EventTransformer/sequential`` transformer.
    ///
    /// All existing `on(.event) { … }` call sites continue to compile unchanged.
    public func on(_ event: Event, handler: @escaping Handler) {
        on(event, transformer: .sequential, handler: handler)
    }
}
