//
//  ScoreBloc.swift
//  BlocProject
//

import Bloc

/// A simple score tracker that demonstrates ``BlocListener`` and `buildWhen`
/// in ``BlocBuilder``.
///
/// The state is a plain `Int` (the current score). Two events are supported:
///
/// - ``ScoreEvent/addPoint``: increments the score by one.
/// - ``ScoreEvent/reset``: returns the score to zero.
///
/// ## BlocListener demo
///
/// `ScoreView` wraps its content with a ``BlocListener`` configured to fire
/// only at every 5-point milestone. The listener is a *side effect* — it shows
/// a milestone banner without rebuilding any of the score UI.
///
/// ## buildWhen demo
///
/// A "Tier" badge uses `BlocBuilder(buildWhen:)` and only redraws when the
/// score crosses a tier boundary (every 10 points). Every emit between
/// boundaries is intentionally ignored, avoiding unnecessary work.
@MainActor
class ScoreBloc: Bloc<Int, ScoreEvent> {

    init() {
        super.init(initialState: 0)

        on(.addPoint) { [weak self] _, emit in
            guard let self else { return }
            emit(state + 1)
        }

        on(.reset) { _, emit in
            emit(0)
        }
    }
}
