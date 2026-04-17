//
//  BlocBuilder.swift
//  Bloc
//
//  Created by Sergio Fraile on 24/06/2025.
//

import SwiftUI

/// A view that provides a Bloc to its content builder.
///
/// `BlocBuilder` is a convenience view that resolves a Bloc from the registry
/// and passes it to a content closure. With iOS 17+ and the `@Observable` macro,
/// this is **optional**—you can access Blocs directly in your views.
///
/// ## Overview
///
/// There are two ways to access Blocs in your views:
///
/// ### Direct Access (Recommended)
///
/// Simply resolve the Bloc as a property:
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
/// ### Using BlocBuilder
///
/// For cases where you prefer a builder pattern:
///
/// ```swift
/// struct CounterView: View {
///     var body: some View {
///         BlocBuilder(CounterBloc.self) { bloc in
///             Text("Count: \(bloc.state)")
///             Button("+") { bloc.send(.increment) }
///         }
///     }
/// }
/// ```
///
/// ## When to use BlocBuilder
///
/// While direct access is simpler, `BlocBuilder` can be useful for:
///
/// - **Scoping**: Limiting where the Bloc reference is available
/// - **Clarity**: Making dependencies explicit in the view structure
/// - **Migration**: Transitioning from older patterns
///
/// ## Controlled rebuilds
///
/// To limit rebuilds to specific state transitions, use ``BlocBuilderWhen``
/// instead. It accepts a `buildWhen` predicate and passes a state snapshot
/// (rather than the live Bloc) to its content closure.
///
/// ## Topics
///
/// ### Creating a Builder
///
/// - ``init(_:content:)``
/// - ``init(bloc:content:)``
public struct BlocBuilder<B: BlocBase, Content: View>: View {
    
    private let bloc: B
    private let content: (B) -> Content
    
    /// Creates a BlocBuilder that resolves a Bloc from the registry.
    ///
    /// The Bloc is resolved using ``BlocRegistry/resolve(_:)`` and passed
    /// to the content closure.
    ///
    /// ```swift
    /// BlocBuilder(CounterBloc.self) { bloc in
    ///     Text("Count: \(bloc.state)")
    ///     Button("+") { bloc.send(.increment) }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - blocType: The type of Bloc to resolve.
    ///   - content: A view builder that receives the resolved Bloc.
    public init(
        _ blocType: B.Type,
        @ViewBuilder content: @escaping (B) -> Content
    ) {
        self.bloc = BlocRegistry.resolve(B.self)
        self.content = content
    }
    
    /// Creates a BlocBuilder with an explicit Bloc instance.
    ///
    /// Use this initializer when you already have a Bloc reference or
    /// want to provide a specific instance:
    ///
    /// ```swift
    /// let myBloc = CounterBloc()
    ///
    /// BlocBuilder(bloc: myBloc) { bloc in
    ///     Text("Count: \(bloc.state)")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - bloc: The Bloc instance to use.
    ///   - content: A view builder that receives the Bloc.
    public init(
        bloc: B,
        @ViewBuilder content: @escaping (B) -> Content
    ) {
        self.bloc = bloc
        self.content = content
    }
    
    public var body: some View {
        content(bloc)
    }
}

// MARK: - BlocBuilderWhen

/// A view that rebuilds its content only when a `buildWhen` predicate approves
/// a state transition.
///
/// Unlike ``BlocBuilder``, which passes the live Bloc to its content closure
/// (causing SwiftUI's `@Observable` system to rebuild on every state change),
/// `BlocBuilderWhen` passes a **state snapshot** and only updates that snapshot
/// when `buildWhen` returns `true`. This prevents any accidental `@Observable`
/// subscriptions inside the content from bypassing the filter.
///
/// ## Usage
///
/// ```swift
/// // Tier badge only redraws when the score crosses a tier boundary.
/// BlocBuilderWhen(ScoreBloc.self,
///     buildWhen: { old, new in old / 10 != new / 10 }
/// ) { state in
///     TierBadge(name: tierName(for: state))   // `state` is B.State, not B
/// }
/// ```
///
/// ## When to use `BlocBuilderWhen`
///
/// - A state struct has many fields but a sub-view only cares about one.
/// - You want a section to update at discrete thresholds, not on every emit.
/// - For the strictest derived-value control, see ``BlocSelector``.
///
/// ## Topics
///
/// ### Creating a Filtered Builder
///
/// - ``init(_:buildWhen:content:)``
public struct BlocBuilderWhen<B: BlocBase, Content: View>: View {

    private let bloc: B
    private let buildWhen: (B.State, B.State) -> Bool
    private let content: (B.State) -> Content

    /// The last state snapshot approved by `buildWhen`.
    ///
    /// Updated only when `buildWhen(previous, new)` returns `true`, which
    /// triggers SwiftUI to re-render `content` with the new value.
    @State private var displayedState: B.State

    /// Creates a `BlocBuilderWhen` that resolves a Bloc from the registry.
    ///
    /// - Parameters:
    ///   - blocType: The type of Bloc to resolve.
    ///   - buildWhen: A predicate receiving `(previous, current)` state snapshots.
    ///     Return `true` to approve a rebuild; `false` to skip it.
    ///   - content: A view builder receiving the last approved state snapshot.
    public init(
        _ blocType: B.Type,
        buildWhen: @escaping (B.State, B.State) -> Bool,
        @ViewBuilder content: @escaping (B.State) -> Content
    ) {
        let b = BlocRegistry.resolve(B.self)
        self.bloc = b
        self.buildWhen = buildWhen
        self.content = content
        self._displayedState = State(initialValue: b.state)
    }

    public var body: some View {
        content(displayedState)
            .onReceive(bloc.statePublisher) { newState in
                guard buildWhen(displayedState, newState) else { return }
                displayedState = newState
            }
    }
}
