//
//  BlocConsumer.swift
//  Bloc
//

import Combine
import SwiftUI

// MARK: - Internal tracker

/// Reference-type container that advances the "previous state" cursor without
/// triggering a SwiftUI re-render.
private final class ConsumerStateTracker<S>: @unchecked Sendable {
    var previous: S
    init(_ state: S) { previous = state }
}

// MARK: - BlocConsumer

/// A view that combines ``BlocListener`` and ``BlocBuilderWhen`` into a single,
/// declarative component.
///
/// Use `BlocConsumer` when a state transition needs **both** a side effect
/// (navigation, banner, sound) **and** a conditional UI rebuild — all gated by
/// their own independent predicates.
///
/// ## When to use BlocConsumer vs BlocListener + BlocBuilderWhen
///
/// | | Prefer | Reason |
/// |---|---|---|
/// | Side effect only | ``BlocListener`` | Simpler, no UI rebuild overhead |
/// | UI rebuild only | Direct property + `@Observable` | Zero boilerplate |
/// | Side effect + controlled rebuild | **`BlocConsumer`** | Single component, one subscription |
///
/// ## Usage
///
/// ```swift
/// // Show a "tier up" animation AND update the tier badge — gated by the same
/// // predicate, driven by a single Combine subscription.
/// BlocConsumer(ScoreBloc.self,
///     listenWhen: { old, new in Tier(score: old) != Tier(score: new) },
///     listener:   { _ in triggerTierAnimation() },
///     buildWhen:  { old, new in Tier(score: old) != Tier(score: new) }
/// ) { state in
///     TierBadge(tier: Tier(score: state))
/// }
/// ```
///
/// Both predicates receive `(previous, current)` states and are evaluated on
/// the same state update. You can use different predicates for each:
///
/// ```swift
/// // The side effect fires every 5 pts; the UI rebuilds every 10 pts.
/// BlocConsumer(ScoreBloc.self,
///     listenWhen: { _, new in new % 5 == 0 },
///     listener:   { state in playChime() },
///     buildWhen:  { old, new in old / 10 != new / 10 }
/// ) { state in
///     TierBadge(tier: Tier(score: state))
/// }
/// ```
///
/// ## Content closure
///
/// The `content` closure receives a **state snapshot** (`B.State`), not the
/// live Bloc. This is intentional: passing a snapshot ensures that `buildWhen`
/// fully controls when the view is rebuilt, without `@Observable` bypassing
/// the filter. To send events from inside `content`, resolve the Bloc directly:
///
/// ```swift
/// BlocConsumer(MyBloc.self, ...) { state in
///     let bloc = BlocRegistry.resolve(MyBloc.self)
///     Text("\(state)")
///     Button("+") { bloc.send(.increment) }
/// }
/// ```
///
/// ## Default behaviour
///
/// Both `listenWhen` and `buildWhen` default to `nil`, which means they always
/// trigger — equivalent to ``BlocListener`` and ``BlocBuilder`` respectively.
///
/// ## Topics
///
/// ### Creating a Consumer
///
/// - ``init(_:listenWhen:listener:buildWhen:content:)``
@MainActor
public struct BlocConsumer<B: BlocBase, Content: View>: View {

    private let bloc: B
    private let listenWhen: ((B.State, B.State) -> Bool)?
    private let listener: (B.State) -> Void
    private let buildWhen: ((B.State, B.State) -> Bool)?
    private let content: (B.State) -> Content

    /// Tracks the last state seen by the *listener* side so the `listenWhen`
    /// predicate can compare `(previous, current)` — same trick as `BlocListener`.
    @State private var listenTracker: ConsumerStateTracker<B.State>

    /// The state snapshot passed to `content`. Updated only when `buildWhen`
    /// returns `true`, preventing unwanted rebuilds.
    @State private var displayedState: B.State

    // MARK: Initialiser

    /// Creates a `BlocConsumer` that resolves a Bloc from the registry.
    ///
    /// - Parameters:
    ///   - blocType: The Bloc type to resolve via ``BlocRegistry``.
    ///   - listenWhen: An optional predicate `(previous, current) -> Bool`.
    ///     The `listener` is only called when this returns `true`.
    ///     Defaults to always calling the listener.
    ///   - listener: A side-effect closure called with the new state.
    ///     Not called for the initial state.
    ///   - buildWhen: An optional predicate `(previous, current) -> Bool`.
    ///     The content snapshot is only updated — triggering a rebuild — when
    ///     this returns `true`. Defaults to always rebuilding.
    ///   - content: A view builder receiving the last approved state snapshot.
    public init(
        _ blocType: B.Type,
        listenWhen: ((B.State, B.State) -> Bool)? = nil,
        listener: @escaping (B.State) -> Void,
        buildWhen: ((B.State, B.State) -> Bool)? = nil,
        @ViewBuilder content: @escaping (B.State) -> Content
    ) {
        let resolvedBloc = BlocRegistry.resolve(B.self)
        self.bloc = resolvedBloc
        self.listenWhen = listenWhen
        self.listener = listener
        self.buildWhen = buildWhen
        self.content = content
        self._listenTracker = State(initialValue: ConsumerStateTracker(resolvedBloc.state))
        self._displayedState = State(initialValue: resolvedBloc.state)
    }

    // MARK: Body

    public var body: some View {
        content(displayedState)
            .onReceive(bloc.statePublisher) { newState in
                // --- Listener side ---
                let previousForListener = listenTracker.previous
                listenTracker.previous = newState
                if listenWhen?(previousForListener, newState) ?? true {
                    listener(newState)
                }

                // --- Builder side ---
                // Use the *displayed* state as the "previous" so buildWhen
                // compares against what the content last rendered, not the
                // last emitted state.
                if buildWhen?(displayedState, newState) ?? true {
                    displayedState = newState
                }
            }
    }
}
