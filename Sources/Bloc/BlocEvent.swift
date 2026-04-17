//
//  BlocEvent.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

/// A type that can be used as an event in a ``Bloc``.
///
/// `BlocEvent` is a type alias for `Equatable & Hashable`. Events must be
/// both equatable (for comparison) and hashable (for use as dictionary keys
/// in event handler registration).
///
/// ## Overview
///
/// Events represent user actions, system occurrences, or anything that
/// should trigger a state change.
///
/// ### Simple Enums
///
/// For basic events without data:
///
/// ```swift
/// enum CounterEvent: Hashable {
///     case increment
///     case decrement
///     case reset
/// }
/// ```
///
/// ### Events with Associated Values
///
/// For events that carry data:
///
/// ```swift
/// enum LoginEvent: Hashable {
///     case emailChanged(String)
///     case passwordChanged(String)
///     case loginButtonTapped
///     case loginSucceeded(User)
///     case loginFailed(String)
/// }
/// ```
///
/// ### Events with Complex Payloads
///
/// For events with multiple values:
///
/// ```swift
/// enum SearchEvent: Hashable {
///     case queryChanged(String)
///     case filtersUpdated(category: String, minPrice: Int, maxPrice: Int)
///     case resultTapped(itemId: String, index: Int)
///     case pageLoaded(items: [Item], hasMore: Bool)
/// }
/// ```
///
/// ## Handling Events
///
/// ### Simple Events
///
/// Use ``Bloc/on(_:handler:)`` for events without associated values:
///
/// ```swift
/// on(.increment) { event, emit in
///     emit(self.state + 1)
/// }
/// ```
///
/// ### Events with Associated Values
///
/// Use ``Bloc/mapEventToState(event:emit:)`` for pattern matching:
///
/// ```swift
/// override func mapEventToState(event: LoginEvent, emit: @escaping Emitter) {
///     switch event {
///     case .emailChanged(let email):
///         var newState = state
///         newState.email = email
///         emit(newState)
///
///     case .loginButtonTapped:
///         emit(LoginState(isLoading: true))
///         Task { await performLogin() }
///
///     // ... handle other events
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// 1. **Use past tense or descriptive names**: `loginButtonTapped`,
///    `dataLoaded`, `errorOccurred`.
///
/// 2. **Keep events focused**: Each event should represent one thing
///    that happened.
///
/// 3. **Include relevant data**: Events should carry any data needed
///    to process them.
///
/// 4. **Consider event sources**: Name events to indicate where they
///    came from: `userTappedLogin`, `apiReturnedError`.
public typealias BlocEvent = Equatable & Hashable
