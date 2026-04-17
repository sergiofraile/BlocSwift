//
//  BlocListener.swift
//  Bloc
//
//  Created by Sergio Fraile on 05/03/2026.
//

import SwiftUI

// MARK: - Internal State Tracker

/// A reference-type container for tracking previous Bloc state without triggering
/// SwiftUI view re-renders.
///
/// Stored as a `@State`-wrapped class so SwiftUI manages the lifetime across
/// view-struct re-creation, while mutations to `previous` remain invisible to
/// the observation system.
private final class BlocListenerTracker<S>: @unchecked Sendable {
    var previous: S
    init(_ state: S) { previous = state }
}

// MARK: - BlocListener

/// A view that reacts to Bloc state changes as side effects, without causing
/// its content to rebuild.
///
/// Use `BlocListener` whenever a state change should trigger a side effect —
/// showing a toast notification, playing a sound, navigating to another screen —
/// but must **not** cause the surrounding UI to rebuild.
///
/// ## Overview
///
/// `BlocListener` resolves a Bloc from the registry, subscribes to its state
/// stream, and calls `listener` whenever the state changes. Unlike
/// ``BlocBuilder``, `BlocListener` never rebuilds its `content` in response to
/// state changes; it is purely for side effects.
///
/// ```swift
/// BlocListener(ScoreBloc.self,
///     listenWhen: { _, new in new > 0 && new % 5 == 0 }
/// ) { state in
///     // Called only at every 5th point — no rebuild triggered
///     showMilestoneBanner("🎯 \(state) points!")
/// } content: {
///     ScoreView()
/// }
/// ```
///
/// ## `listenWhen`
///
/// Provide a `listenWhen` predicate to call `listener` only for specific
/// transitions. The closure receives `(previous, current)` states and must
/// return `true` to invoke the listener:
///
/// ```swift
/// BlocListener(AuthBloc.self,
///     listenWhen: { prev, current in
///         prev.isAuthenticated != current.isAuthenticated
///     }
/// ) { state in
///     state.isAuthenticated ? navigator.push(.home) : navigator.pop(to: .login)
/// } content: {
///     LoginForm()
/// }
/// ```
///
/// When `listenWhen` is omitted, `listener` is called on **every** state
/// change.
///
/// ## Side-effect only
///
/// The `listener` closure runs on the main thread. It is safe to perform
/// SwiftUI state mutations inside it (e.g. updating a `@State` property to
/// show an overlay):
///
/// ```swift
/// @State private var milestoneText: String? = nil
///
/// BlocListener(ScoreBloc.self,
///     listenWhen: { _, new in new % 10 == 0 && new > 0 }
/// ) { state in
///     milestoneText = "New high: \(state)!"
/// } content: {
///     ScoreContentView()
/// }
/// ```
///
/// ## Combining with BlocBuilder
///
/// Nest a ``BlocBuilder`` inside `BlocListener`'s `content` closure when you
/// need both selective rebuilds and side effects:
///
/// ```swift
/// BlocListener(AuthBloc.self,
///     listenWhen: { prev, curr in prev.isAuthenticated != curr.isAuthenticated }
/// ) { state in
///     if state.isAuthenticated { navigator.push(.home) }
/// } content: {
///     BlocBuilder(AuthBloc.self) { bloc in
///         LoginForm(bloc: bloc)
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Listener
///
/// - ``init(_:listenWhen:listener:content:)``
@MainActor
public struct BlocListener<B: BlocBase, Content: View>: View {

    private let bloc: B
    private let listenWhen: ((B.State, B.State) -> Bool)?
    private let listener: (B.State) -> Void
    private let content: () -> Content

    /// A class-based tracker so mutations to `previous` do not trigger
    /// SwiftUI re-renders. Wrapped in `@State` so SwiftUI manages the lifetime.
    @State private var tracker: BlocListenerTracker<B.State>

    // MARK: Initialiser

    /// Creates a `BlocListener` that resolves a Bloc from the registry.
    ///
    /// - Parameters:
    ///   - blocType: The Bloc type to resolve via ``BlocRegistry``.
    ///   - listenWhen: An optional predicate receiving `(previous, current)`
    ///     states. The listener is called only when this returns `true`.
    ///     Defaults to `true` on every state change when omitted.
    ///   - listener: A side-effect closure called with the new state whenever
    ///     `listenWhen` returns `true`. It is **not** called for the initial
    ///     state.
    ///   - content: The view hierarchy to render. Never rebuilt in response to
    ///     Bloc state changes.
    public init(
        _ blocType: B.Type,
        listenWhen: ((B.State, B.State) -> Bool)? = nil,
        listener: @escaping (B.State) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        let resolvedBloc = BlocRegistry.resolve(B.self)
        self.bloc = resolvedBloc
        self.listenWhen = listenWhen
        self.listener = listener
        self.content = content
        self._tracker = State(initialValue: BlocListenerTracker(resolvedBloc.state))
    }

    // MARK: Body

    public var body: some View {
        content()
            .onReceive(bloc.statePublisher) { newState in
                let previous = tracker.previous
                // Always advance the cursor regardless of whether we fire.
                tracker.previous = newState
                let shouldListen = listenWhen?(previous, newState) ?? true
                guard shouldListen else { return }
                listener(newState)
            }
    }
}
