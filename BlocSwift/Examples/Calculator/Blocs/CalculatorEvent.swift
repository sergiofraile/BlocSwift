//
//  CalculatorEvent.swift
//  BlocSwift
//

import Bloc

/// A mathematical operation the calculator can perform.
enum Operation: String, Hashable, CaseIterable {
    case add      = "+"
    case subtract = "−"
    case multiply = "×"
    case divide   = "÷"
}

/// Events the calculator Bloc can process.
enum CalculatorEvent: BlocEvent {
    case digit(Int)
    case operation(Operation)
    case equals
    case clear
    case delete
    case decimal
    case toggleSign
    case percentage
}

extension CalculatorEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .digit(let d):        return "digit(\(d))"
        case .operation(let op):   return "operation(\(op.rawValue))"
        case .equals:              return "equals"
        case .clear:               return "clear"
        case .delete:              return "delete"
        case .decimal:             return "decimal"
        case .toggleSign:          return "toggleSign"
        case .percentage:          return "percentage"
        }
    }
}
