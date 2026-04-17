//
//  BlocError.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

/// A concrete error type for common Bloc operations.
///
/// `BlocError` provides a set of well-known error cases you can use when
/// signalling errors via ``Bloc/addError(_:)``.
///
/// ## Overview
///
/// You are not required to use `BlocError`—``Bloc/addError(_:)`` accepts
/// any `Error`. However, `BlocError` is useful when no domain-specific error
/// type is available:
///
/// ```swift
/// on(.fetchData) { [weak self] event, emit in
///     guard let self else { return }
///     guard isNetworkAvailable else {
///         addError(BlocError.defaultError)
///         return
///     }
///     // ...
/// }
/// ```
///
/// Observe errors via ``Bloc/errorsPublisher``:
///
/// ```swift
/// bloc.errorsPublisher
///     .sink { error in
///         if let blocError = error as? BlocError {
///             print("Bloc error: \(blocError)")
///         }
///     }
///     .store(in: &cancellables)
/// ```
///
/// ## Topics
///
/// ### Error Cases
///
/// - ``defaultError``
public enum BlocError: Error {
    
    /// A generic error that occurred during Bloc operations.
    ///
    /// Use this as a placeholder when no more specific error type is available.
    /// Consider defining a domain-specific `Error` type for production code.
    case defaultError
}
