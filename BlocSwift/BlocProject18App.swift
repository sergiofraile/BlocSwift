//
//  BlocSwiftApp.swift
//  BlocSwift
//
//  Created by Sergio Fraile Carmena on 06/08/2025.
//

import Bloc
import SwiftUI
import Pulse
import PulseProxy
import PulseUI

@main
struct BlocSwiftApp: App {

    // Blocs and Cubits are stored as properties so they survive body re-evaluations.
    // Declaring them inside body would create fresh instances on every render,
    // causing BlocRegistry to be replaced and all state to be lost.
    private let counterBloc    = CounterBloc()
    private let calculatorBloc = CalculatorBloc()
    private let formulaOneBloc = FormulaOneBloc()
    private let lorcanaBloc    = LorcanaBloc(networkService: LorcanaNetworkService())
    private let scoreBloc      = ScoreBloc()
    private let timerCubit     = TimerCubit()

    init() {
        BlocObserver.shared = AppBlocObserver()
#if DEBUG
        NetworkLogger.enableProxy()
#endif
    }

    var body: some Scene {
        WindowGroup {
            BlocProvider(with: [counterBloc, calculatorBloc, formulaOneBloc, lorcanaBloc, scoreBloc, timerCubit]) {
                ExamplesSplitView()
                    .frame(minWidth: 375.0, minHeight: 600.0)
            }
        }
    }
}
