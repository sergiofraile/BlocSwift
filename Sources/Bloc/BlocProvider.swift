//
//  BlocProvider.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

import SwiftUI

/// A SwiftUI view that registers Blocs and makes them available to descendant views.
///
/// `BlocProvider` is the entry point for the Bloc pattern in your app. It registers
/// Bloc instances with the ``BlocRegistry``, allowing any descendant view to resolve
/// them using ``BlocRegistry/resolve(_:)``.
///
/// ## Overview
///
/// Wrap your root view (or a subtree) with `BlocProvider` to make Blocs available:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             BlocProvider(with: [
///                 CounterBloc(),
///                 AuthBloc(authService: LiveAuthService()),
///                 SettingsBloc(initialState: .default)
///             ]) {
///                 ContentView()
///             }
///         }
///     }
/// }
/// ```
///
/// ## Dependency Injection
///
/// `BlocProvider` is the ideal place to inject dependencies into your Blocs:
///
/// ```swift
/// BlocProvider(with: [
///     // Inject live services for production
///     UserBloc(userService: LiveUserService()),
///     AnalyticsBloc(tracker: FirebaseTracker())
/// ]) {
///     MainView()
/// }
/// ```
///
/// For previews and tests, inject mock dependencies:
///
/// ```swift
/// #Preview {
///     BlocProvider(with: [
///         UserBloc(userService: MockUserService())
///     ]) {
///         ProfileView()
///     }
/// }
/// ```
///
/// ## Accessing Blocs
///
/// Descendant views access registered Blocs via ``BlocRegistry``:
///
/// ```swift
/// struct CounterView: View {
///     let counterBloc = BlocRegistry.resolve(CounterBloc.self)
///
///     var body: some View {
///         Text("Count: \(counterBloc.state)")
///         Button("+") { counterBloc.send(.increment) }
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Provider
///
/// - ``init(with:content:)``
public struct BlocProvider<Content: View>: View {
    
    let content: () -> Content
    
    /// Creates a BlocProvider that registers the specified Blocs.
    ///
    /// Use this initializer to register Blocs at the root of your app or at
    /// any point where you need to scope Bloc availability.
    ///
    /// ```swift
    /// BlocProvider(with: [
    ///     CounterBloc(),
    ///     AuthBloc(authService: LiveAuthService())
    /// ]) {
    ///     ContentView()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - blocs: An array of ``Bloc`` or ``Cubit`` instances to register.
    ///     Each type can only be registered once.
    ///   - content: A view builder that creates the content view. All
    ///     descendant views can access the registered Blocs and Cubits.
    public init(with blocs: [any StateEmitter], @ViewBuilder content: @escaping () -> Content) {
        _ = BlocRegistry(with: blocs)
        self.content = content
    }
    
    public var body: some View {
        content()
    }
}
