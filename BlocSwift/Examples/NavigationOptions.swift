//
//  NavigationOptions.swift
//  BlocProject
//
//  Created by Sergio Fraile Carmena on 02/07/2025.
//

import SwiftUI

enum NavigationOptions: Equatable, Hashable, Identifiable {
    
    case counter, formulaOne, lorcana, calculator, heartbeat, score, timer
    
    static let mainPages: [NavigationOptions] = [.counter, .timer, .calculator, .heartbeat, .score, .formulaOne, .lorcana]
    
    var id: String {
        switch self {
        case .counter:    return "counter"
        case .formulaOne: return "formula one"
        case .lorcana:    return "lorcana"
        case .calculator: return "calculator"
        case .heartbeat:  return "heartbeat"
        case .score:      return "score"
        case .timer:      return "timer"
        }
    }
    
    var name: LocalizedStringResource {
        switch self {
        case .counter:
            return LocalizedStringResource("Counter", comment: "Title for the Counter example, shown in the sidebar.")
        case .formulaOne:
            return LocalizedStringResource("Formula One", comment: "Title for the F1 example, shown in the sidebar.")
        case .lorcana:
            return LocalizedStringResource("Lorcana", comment: "Title for the Lorcana TCG example, shown in the sidebar.")
        case .calculator:
            return LocalizedStringResource("Calculator", comment: "Title for the Calculator lifecycle hooks example.")
        case .heartbeat:
            return LocalizedStringResource("Heartbeat", comment: "Title for the Heartbeat scoped lifecycle example.")
        case .score:
            return LocalizedStringResource("Score Board", comment: "Title for the Score Board BlocListener + buildWhen example.")
        case .timer:
            return LocalizedStringResource("Stopwatch", comment: "Title for the Stopwatch Cubit example.")
        }
    }
    
    var subtitle: String {
        switch self {
        case .counter:    return "Basic state increment/decrement"
        case .formulaOne: return "API-driven driver standings"
        case .lorcana:    return "Disney TCG card browser"
        case .calculator: return "Lifecycle hooks: onEvent, onChange, onTransition, onError"
        case .heartbeat:  return "Scoped Bloc: close() on screen dismiss"
        case .score:      return "BlocListener side-effects + buildWhen rebuilds"
        case .timer:      return "Cubit: direct method calls, no events"
        }
    }
    
    var symbolName: String {
        switch self {
        case .counter:    return "plusminus.circle.fill"
        case .formulaOne: return "flag.checkered"
        case .lorcana:    return "wand.and.stars"
        case .calculator: return "function"
        case .heartbeat:  return "waveform.path.ecg"
        case .score:      return "gamecontroller.fill"
        case .timer:      return "stopwatch.fill"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .counter:
            return [Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.9)]
        case .formulaOne:
            return [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.8, green: 0.1, blue: 0.1)]
        case .lorcana:
            return [Color(red: 0.6, green: 0.3, blue: 0.9), Color(red: 0.4, green: 0.2, blue: 0.7)]
        case .calculator:
            return [Color(red: 1.0, green: 0.55, blue: 0.1), Color(red: 0.85, green: 0.35, blue: 0.0)]
        case .heartbeat:
            return [Color(red: 0.2, green: 0.8, blue: 0.55), Color(red: 0.1, green: 0.6, blue: 0.4)]
        case .score:
            return [Color(red: 0.55, green: 0.25, blue: 0.90), Color(red: 0.35, green: 0.10, blue: 0.70)]
        case .timer:
            return [Color(red: 0.1, green: 0.85, blue: 0.55), Color(red: 0.05, green: 0.60, blue: 0.40)]
        }
    }
    
    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .counter:    CounterView()
        case .formulaOne: FormulaOneView()
        case .lorcana:    LorcanaView()
        case .calculator: CalculatorView()
        case .heartbeat:  HeartbeatView()
        case .score:      ScoreView()
        case .timer:      TimerView()
        }
    }
}
