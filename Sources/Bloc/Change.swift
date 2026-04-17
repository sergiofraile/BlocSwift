//
//  Change.swift
//  Bloc
//
//  Created by Sergio Fraile on 04/03/2026.
//

/// Represents a state transition in a ``Cubit`` or ``Bloc``.
///
/// A `Change` captures the state immediately before and after a call to
/// ``Bloc/emit(_:)``. It is delivered to ``Bloc/onChange(_:)`` on every
/// emission, regardless of what triggered it.
///
/// ```swift
/// override func onChange(_ change: Change<Int>) {
///     super.onChange(change)
///     print(change)
///     // Change { currentState: 0, nextState: 1 }
/// }
/// ```
///
/// ## See Also
///
/// - ``Transition`` — includes the event that caused the change (Bloc only)
/// - ``Bloc/onChange(_:)``
public struct Change<S: BlocState> {

    /// The state before the emission.
    public let currentState: S

    /// The state after the emission.
    public let nextState: S
}

extension Change: CustomStringConvertible {
    public var description: String {
        "Change { currentState: \(currentState), nextState: \(nextState) }"
    }
}
