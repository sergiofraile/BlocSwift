//
//  BlocSelector.swift
//  Bloc
//

import SwiftUI

/// A view that derives a value from a Bloc's state and rebuilds its content
/// **only** when that derived value changes.
///
/// `BlocSelector` is the most targeted rebuild primitive in the Bloc library.
/// Where ``BlocBuilder`` rebuilds whenever any part of the state changes and
/// ``BlocBuilderWhen`` rebuilds when a predicate approves the whole state
/// transition, `BlocSelector` projects the state down to a single `Value` via a
/// `selector` closure and uses `Equatable` equality to suppress redundant
/// rebuilds.
///
/// ## Overview
///
/// Supply a `selector` that extracts the slice of state the view cares about.
/// The content closure receives that derived value rather than the full Bloc,
/// so it cannot accidentally subscribe to fields it does not use:
///
/// ```swift
/// // Only rebuilds when isLoading flips — card list updates are ignored
/// BlocSelector(LorcanaBloc.self, selector: \.isLoading) { isLoading in
///     if isLoading {
///         ProgressView("Summoning cards…")
///     }
/// }
/// ```
///
/// KeyPath shorthand (shown above) works because Swift automatically promotes
/// a `KeyPath<State, Value>` to a `(State) -> Value` function at the call site.
///
/// ## When to use `BlocSelector`
///
/// | Need | Use |
/// |------|-----|
/// | Full Bloc access with automatic observation | ``BlocBuilder`` or direct `@Observable` access |
/// | Rebuild only at discrete thresholds (e.g. every 10 pts) | ``BlocBuilderWhen`` |
/// | Rebuild only when a specific derived value changes | `BlocSelector` |
///
/// ## Composing multiple selectors
///
/// Compose a custom `Equatable` struct to derive multiple fields at once while
/// still suppressing redundant rebuilds:
///
/// ```swift
/// struct PaginationStatus: Equatable {
///     let isLoadingMore: Bool
///     let hasMorePages: Bool
///     let cardCount: Int
/// }
///
/// BlocSelector(
///     LorcanaBloc.self,
///     selector: { PaginationStatus(isLoadingMore: $0.isLoadingMore,
///                                  hasMorePages:  $0.hasMorePages,
///                                  cardCount:     $0.cards.count) }
/// ) { status in
///     PaginationFooter(status: status)
/// }
/// ```
///
/// ## Topics
///
/// ### Creating a Selector
///
/// - ``init(_:selector:content:)``
public struct BlocSelector<B: BlocBase, Value: Equatable, Content: View>: View {

    private let bloc: B
    private let selector: (B.State) -> Value
    private let content: (Value) -> Content

    /// The last derived value emitted by the selector.
    ///
    /// Initialised from the Bloc's current state so the content renders
    /// immediately. Only updated — and content only rebuilt — when the new
    /// derived value differs from the previous one under `==`.
    @State private var selectedValue: Value

    // MARK: Initialiser

    /// Creates a `BlocSelector` that resolves a Bloc from the registry.
    ///
    /// - Parameters:
    ///   - blocType: The Bloc type to resolve via ``BlocRegistry``.
    ///   - selector: A closure (or key-path shorthand) that projects the full
    ///     state down to a single `Equatable` value. The closure is called on
    ///     every state emission; content rebuilds only when the result changes.
    ///   - content: A view builder receiving the derived value. The closure
    ///     receives `Value`, not the full Bloc, preventing accidental
    ///     subscriptions to other state fields.
    public init(
        _ blocType: B.Type,
        selector: @escaping (B.State) -> Value,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        let b = BlocRegistry.resolve(B.self)
        self.bloc = b
        self.selector = selector
        self.content = content
        self._selectedValue = State(initialValue: selector(b.state))
    }

    // MARK: Body

    public var body: some View {
        content(selectedValue)
            .onReceive(
                bloc.statePublisher
                    .map(selector)
                    .removeDuplicates()
            ) { newValue in
                selectedValue = newValue
            }
    }
}
