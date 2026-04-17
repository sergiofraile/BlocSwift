//
//  BlocState.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

/// A type that can be used as state in a ``Bloc``.
///
/// `BlocState` is a type alias for `Equatable`. Any type that conforms to
/// `Equatable` can be used as state in a Bloc.
///
/// ## Overview
///
/// States represent the data your UI needs to render. You can use:
///
/// ### Primitive Types
///
/// For simple cases, use built-in types directly:
///
/// ```swift
/// class CounterBloc: Bloc<Int, CounterEvent> { ... }
/// class ToggleBloc: Bloc<Bool, ToggleEvent> { ... }
/// class NameBloc: Bloc<String, NameEvent> { ... }
/// ```
///
/// ### Custom Types
///
/// For complex state, define a struct:
///
/// ```swift
/// struct LoginState: Equatable {
///     var email: String = ""
///     var password: String = ""
///     var isLoading: Bool = false
///     var error: String?
///     var user: User?
/// }
///
/// class LoginBloc: Bloc<LoginState, LoginEvent> { ... }
/// ```
///
/// ### Enums for Discrete States
///
/// Enums work well for mutually exclusive states:
///
/// ```swift
/// enum DataState: Equatable {
///     case initial
///     case loading
///     case loaded([Item])
///     case error(String)
/// }
///
/// class DataBloc: Bloc<DataState, DataEvent> { ... }
/// ```
///
/// ## Best Practices
///
/// 1. **Keep states immutable**: Create new state instances rather than
///    mutating existing ones.
///
/// 2. **Make states `Equatable`**: This enables SwiftUI to optimize
///    re-renders by detecting when state actually changed.
///
/// 3. **Include all UI-relevant data**: The state should contain everything
///    the view needs to render.
///
/// 4. **Avoid computed properties**: If possible, store derived data
///    directly in the state to simplify equality checks.
public typealias BlocState = Equatable
