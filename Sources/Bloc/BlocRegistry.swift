//
//  BlocRegistry.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

/// A centralized registry for accessing Bloc instances.
///
/// `BlocRegistry` provides type-safe access to Blocs that have been registered
/// via ``BlocProvider``. It acts as a service locator, allowing any view in the
/// hierarchy to resolve the Blocs it needs.
///
/// ## Overview
///
/// You don't create a `BlocRegistry` directly. Instead, ``BlocProvider``
/// initializes it automatically when you provide Blocs:
///
/// ```swift
/// BlocProvider(with: [
///     CounterBloc(),
///     AuthBloc(authService: liveService)
/// ]) {
///     ContentView()
/// }
/// ```
///
/// Then, resolve Blocs anywhere in the view hierarchy:
///
/// ```swift
/// struct CounterView: View {
///     let counterBloc = BlocRegistry.resolve(CounterBloc.self)
///
///     var body: some View {
///         Text("Count: \(counterBloc.state)")
///     }
/// }
/// ```
///
/// ## Error Handling
///
/// If you try to resolve a Bloc that hasn't been registered, the app will
/// crash with a helpful error message indicating:
///
/// - Which Bloc type was requested
/// - Which Blocs are currently registered
/// - How to fix the issue
///
/// This fail-fast behavior catches configuration errors early in development.
///
/// ## Thread Safety
///
/// `BlocRegistry` is marked with `@MainActor` to ensure thread-safe access.
/// All Bloc operations should occur on the main thread.
///
/// ## Topics
///
/// ### Resolving Blocs
///
/// - ``resolve(_:)``
@MainActor
public final class BlocRegistry {
    
    // MARK: - Singleton

    private static var shared: BlocRegistry?

    // MARK: - Storage

    private var registeredBlocs: [ObjectIdentifier: any StateEmitter] = [:]

    /// Flat list used by `deinit`, which cannot access the `@MainActor`-isolated
    /// `registeredBlocs` dictionary directly.
    ///
    /// Written once in `init` (on the main thread) and only read in `deinit`
    /// (also on the main thread, because every reference to `BlocRegistry` is
    /// held by `@MainActor` code). Marked `nonisolated(unsafe)` to satisfy the
    /// compiler's strict concurrency checks.
    nonisolated(unsafe) private var registeredBlocsForDeinit: [any StateEmitter] = []

    /// Whether this registry is still the active one.
    ///
    /// Set to `false` by the next registry's `init` before replacing
    /// `BlocRegistry.shared`. Guarded in `deinit` so only the registry that
    /// is active at deallocation time triggers `close()` on its Blocs.
    ///
    /// Marked `nonisolated(unsafe)` so `deinit` (which is non-isolated) can
    /// read it safely. In practice all writes and reads happen on the main thread.
    nonisolated(unsafe) private var isActive = true

    // MARK: - Initialization

    /// Creates a new registry with the specified Blocs.
    ///
    /// - Note: This initializer is called internally by ``BlocProvider``.
    ///   You don't need to create a registry manually.
    ///
    /// - Parameter blocs: The Bloc instances to register.
    @usableFromInline
    init(with blocs: [any StateEmitter]) {
        for bloc in blocs {
            let key = ObjectIdentifier(type(of: bloc))
            registeredBlocs[key] = bloc
        }
        registeredBlocsForDeinit = blocs
        // Deactivate the previous registry before replacing it, so its deinit
        // knows not to close Blocs that are still in use by this new registry.
        BlocRegistry.shared?.isActive = false
        BlocRegistry.shared = self
    }

    deinit {
        // Only the registry that was still active at the time of deallocation
        // should close its Blocs. Replaced registries are deactivated in init.
        guard isActive else { return }
        let blocs = registeredBlocsForDeinit
        Task { @MainActor [blocs] in
            blocs.forEach { $0.close() }
        }
    }
    
    // MARK: - Type-safe Resolution
    
    /// Resolves a Bloc by its concrete type.
    ///
    /// Use this method to access a registered Bloc from any view:
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
    /// ## Fatal Errors
    ///
    /// This method will crash if:
    ///
    /// 1. **No BlocProvider exists**: The registry hasn't been initialized.
    ///    Make sure to wrap your view hierarchy with ``BlocProvider``.
    ///
    /// 2. **Bloc not registered**: The requested Bloc type wasn't included
    ///    in the `BlocProvider(with:)` array.
    ///
    /// The error message will include the currently registered Blocs and
    /// instructions for fixing the issue.
    ///
    /// - Parameter blocType: The type of Bloc to resolve (e.g., `CounterBloc.self`).
    /// - Returns: The registered Bloc instance.
    /// Resolves a Bloc or Cubit by its concrete type.
    ///
    /// Works for any type that conforms to ``StateEmitter`` — both ``Bloc``
    /// subclasses and ``Cubit`` subclasses:
    ///
    /// ```swift
    /// let counterBloc = BlocRegistry.resolve(CounterBloc.self)
    /// let timerCubit  = BlocRegistry.resolve(TimerCubit.self)
    /// ```
    ///
    /// - Parameter type: The concrete type to resolve.
    /// - Returns: The registered instance.
    public static func resolve<T: StateEmitter>(_ emitterType: T.Type) -> T {
        guard let registry = shared else {
            fatalError("""
                BlocRegistry has not been initialized.
                
                Make sure to wrap your view hierarchy with BlocProvider:
                
                    BlocProvider(with: [
                        \(T.self)(...)
                    ]) {
                        YourContentView()
                    }
                """)
        }
        
        let key = ObjectIdentifier(T.self)
        
        guard let emitter = registry.registeredBlocs[key] as? T else {
            let registeredTypes = registry.registeredBlocs.keys
                .compactMap { registry.registeredBlocs[$0] }
                .map { String(describing: type(of: $0)) }
                .joined(separator: ", ")
            
            fatalError("""
                '\(T.self)' has not been registered.
                
                Currently registered state emitters: [\(registeredTypes.isEmpty ? "none" : registeredTypes)]
                
                Make sure to register it in your BlocProvider:
                
                    BlocProvider(with: [
                        \(T.self)(...),
                        // ... other blocs / cubits
                    ]) {
                        YourContentView()
                    }
                """)
        }
        
        return emitter
    }
    
    // MARK: - Hydration Utilities

    /// Calls ``AnyHydratedBloc/resetToInitialState()`` on every registered
    /// ``HydratedBloc``, then clears any remaining keys from
    /// ``UserDefaultsStorage``.
    ///
    /// Use this as a "clean slate" action — equivalent to wiping storage and
    /// reinstalling the app, but applied immediately without a restart:
    ///
    /// ```swift
    /// // In your settings or debug UI
    /// BlocRegistry.resetAllHydratedBlocs()
    /// ```
    public static func resetAllHydratedBlocs() {
        guard let registry = shared else { return }
        for bloc in registry.registeredBlocs.values {
            (bloc as? any AnyHydratedBloc)?.resetToInitialState()
        }
        // Belt-and-suspenders: wipe any keys whose blocs are not registered.
        UserDefaultsStorage.shared.clear()
    }

    // MARK: - Legacy API
    
    /// Resolves a Bloc by its State and Event types.
    ///
    /// - Warning: This method is deprecated. Use ``resolve(_:)`` with the
    ///   concrete Bloc type instead for better type safety and clearer code.
    ///
    /// - Parameters:
    ///   - state: The State type of the Bloc.
    ///   - event: The Event type of the Bloc.
    /// - Returns: The registered Bloc instance.
    @available(*, deprecated, message: "Use resolve(_:) with the concrete Bloc type instead")
    public static func bloc<S: BlocState, E: BlocEvent>(for state: S.Type, event: E.Type) -> Bloc<S, E> {
        guard let registry = shared else {
            fatalError("BlocRegistry has not been initialized. Wrap your view hierarchy with BlocProvider.")
        }
        
        for (_, emitter) in registry.registeredBlocs {
            if let typedBloc = emitter as? Bloc<S, E> {
                return typedBloc
            }
        }
        
        fatalError("Bloc for State '\(S.self)' and Event '\(E.self)' hasn't been registered in BlocProvider.")
    }
}
