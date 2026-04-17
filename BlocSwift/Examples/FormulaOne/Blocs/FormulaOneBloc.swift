//
//  FormulaOneBloc.swift
//  BlocProject
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Bloc
import Foundation

@MainActor
class FormulaOneBloc: Bloc<FormulaOneState, FormulaOneEvent> {

    override init(initialState: FormulaOneState = .initial) {
        super.init(initialState: initialState)

        self.on(.clear) { _, emit in
            emit(.initial)
        }
    }

    override func mapEventToState(event: FormulaOneEvent, emit: @escaping (Bloc<FormulaOneState, FormulaOneEvent>.State) -> Void) {
        if case .loadChampionship = event {
            emit(.loading)
            Task { await loadChampionship() }
        }
    }

    fileprivate func loadChampionship() async {
        do {
            let drivers = try await FormulaOneNetworkService().fetchDriversChampionship()
            emit(.loaded(drivers))
        } catch {
            addError(error)
            emit(.error(FormulaOneError()))
        }
    }
}
