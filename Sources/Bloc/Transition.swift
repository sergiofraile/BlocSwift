//
//  Transition.swift
//  Bloc
//
//  Created by Sergio Fraile on 04/03/2026.
//

/// Represents a full state transition caused by a specific event in a ``Bloc``.
///
/// A `Transition` extends ``Change`` by adding the event that triggered the
/// state change. It is delivered to ``Bloc/onTransition(_:)`` whenever
/// ``Bloc/emit(_:)`` is called synchronously within an event handler.
///
/// ```swift
/// override func onTransition(_ transition: Transition<CounterEvent, Int>) {
///     super.onTransition(transition)
///     print(transition)
///     // Transition { currentState: 0, event: increment, nextState: 1 }
/// }
/// ```
///
/// > Note: `onTransition` fires for state changes that happen synchronously
/// > during event processing. Emissions from within a `Task` (async context)
/// > are captured by ``Bloc/onChange(_:)`` only.
///
/// ## See Also
///
/// - ``Change`` — state change without event context
/// - ``Bloc/onTransition(_:)``
public struct Transition<E: BlocEvent, S: BlocState> {

    /// The state before the emission.
    public let currentState: S

    /// The event that triggered this transition.
    public let event: E

    /// The state after the emission.
    public let nextState: S
}

extension Transition: CustomStringConvertible {
    public var description: String {
        "Transition { currentState: \(currentState), event: \(event), nextState: \(nextState) }"
    }
}
