//
//  CounterBloc.swift
//  BlocProject
//
//  Created by Sergio Fraile on 16/06/2025.
//

import Bloc

/// A simple counter that demonstrates ``HydratedBloc`` state persistence.
///
/// The current count survives app restarts — it is automatically saved to
/// `UserDefaults` on every increment/decrement and rehydrated when the app
/// launches again. `Int` conforms to `Codable` out of the box, so no extra
/// setup is needed.
///
/// - To reset the counter and clear storage immediately, call ``resetToInitialState()``.
/// - To only wipe storage without affecting the running session, call ``clearStoredState()``.
@MainActor
class CounterBloc: HydratedBloc<Int, CounterEvent> {

    enum Consts {
        static let initialState: Int = 0
    }

    init() {
        super.init(initialState: Consts.initialState)

        on(.increment) { [weak self] _, emit in
            guard let self else { return }
            emit(state + 1)
        }

        on(.decrement) { [weak self] _, emit in
            guard let self else { return }
            emit(state - 1)
        }

        on(.reset) { _, emit in
            emit(Consts.initialState)
        }
    }
}
