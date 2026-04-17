//
//  CalculatorBloc.swift
//  BlocSwift
//

import Bloc
import Foundation

// MARK: - Error

enum CalculatorError: Error, LocalizedError {
    case divisionByZero

    var errorDescription: String? {
        switch self {
        case .divisionByZero: return "Division by zero"
        }
    }
}

// MARK: - Bloc

/// A Bloc that implements a standard four-function calculator.
///
/// This example is designed to showcase the four lifecycle hooks introduced
/// alongside ``Change`` and ``Transition``:
///
/// - ``Bloc/onEvent(_:)`` — fires before every event is processed
/// - ``Bloc/onTransition(_:)`` — fires when state changes synchronously within a handler
/// - ``Bloc/onChange(_:)`` — fires on every state emission
/// - ``Bloc/onError(_:)`` — fires when ``Bloc/addError(_:)`` is called (e.g. divide by zero)
///
/// All four hooks append entries to the public ``lifecycleLog``, which the
/// ``CalculatorView`` displays in real time so you can watch the Bloc's
/// internals as you tap buttons.
@MainActor
class CalculatorBloc: Bloc<CalculatorState, CalculatorEvent> {

    // MARK: - Lifecycle Log

    /// A live log of every lifecycle hook invocation.
    /// Observed directly by the view to show Bloc internals in real time.
    let lifecycleLog = BlocLifecycleLog()

    // MARK: - Init

    init() {
        super.init(initialState: .initial)
    }

    // MARK: - Event → State

    override func mapEventToState(event: CalculatorEvent, emit: @escaping Emitter) {
        switch event {
        case .digit(let d):         handleDigit(d, emit: emit)
        case .operation(let op):    handleOperation(op, emit: emit)
        case .equals:               handleEquals(emit: emit)
        case .clear:                emit(.initial)
        case .delete:               handleDelete(emit: emit)
        case .decimal:              handleDecimal(emit: emit)
        case .toggleSign:           handleToggleSign(emit: emit)
        case .percentage:           handlePercentage(emit: emit)
        }
    }

    // MARK: - Lifecycle Hooks (demonstrating the feature)

    override func onEvent(_ event: CalculatorEvent) {
        super.onEvent(event)
        lifecycleLog.append(kind: .event, message: "\(event)")
    }

    override func onChange(_ change: Change<CalculatorState>) {
        super.onChange(change)
        lifecycleLog.append(
            kind: .change,
            message: "\(change.currentState.displayValue) → \(change.nextState.displayValue)"
        )
    }

    override func onTransition(_ transition: Transition<CalculatorEvent, CalculatorState>) {
        super.onTransition(transition)
        lifecycleLog.append(
            kind: .transition,
            message: "\(transition.currentState.displayValue) — \(transition.event) → \(transition.nextState.displayValue)"
        )
    }

    override func onError(_ error: Error) {
        super.onError(error)
        lifecycleLog.append(kind: .error, message: error.localizedDescription ?? "\(error)")
    }

    override func onClose() {
        super.onClose()
        lifecycleLog.append(kind: .close, message: "Bloc closed — send() and emit() are now no-ops")
    }

    // MARK: - Private Handlers

    private func handleDigit(_ digit: Int, emit: @escaping Emitter) {
        var s = state
        if s.isNewEntry || s.displayValue == "0" {
            s.displayValue = digit == 0 ? "0" : "\(digit)"
            s.isNewEntry = false
        } else {
            guard s.displayValue.replacingOccurrences(of: "-", with: "").count < 9 else { return }
            s.displayValue += "\(digit)"
        }
        s.hasError = false
        emit(s)
    }

    private func handleOperation(_ op: Operation, emit: @escaping Emitter) {
        var s = state
        // Chain: if there's a pending op and the user hasn't started a new operand yet,
        // evaluate the existing expression before storing the new operation.
        if let pending = s.pendingOperation, !s.isNewEntry, let stored = s.storedValue {
            s = evaluated(state: s, stored: stored, current: s.currentDoubleValue, op: pending)
            guard !s.hasError else { emit(s); return }
        }
        s.storedValue = s.currentDoubleValue
        s.pendingOperation = op
        s.isNewEntry = true
        emit(s)
    }

    private func handleEquals(emit: @escaping Emitter) {
        guard let op = state.pendingOperation, let stored = state.storedValue else { return }
        var s = evaluated(state: state, stored: stored, current: state.currentDoubleValue, op: op)
        s.pendingOperation = nil
        s.storedValue = nil
        s.isNewEntry = true
        emit(s)
    }

    private func handleDelete(emit: @escaping Emitter) {
        var s = state
        guard !s.hasError else { emit(.initial); return }
        if s.displayValue.count > 1 {
            s.displayValue = String(s.displayValue.dropLast())
            if s.displayValue == "-" { s.displayValue = "0" }
        } else {
            s.displayValue = "0"
        }
        emit(s)
    }

    private func handleDecimal(emit: @escaping Emitter) {
        var s = state
        if s.isNewEntry {
            s.displayValue = "0."
            s.isNewEntry = false
        } else if !s.displayValue.contains(".") {
            s.displayValue += "."
        }
        emit(s)
    }

    private func handleToggleSign(emit: @escaping Emitter) {
        var s = state
        guard s.displayValue != "0", !s.hasError else { return }
        if s.displayValue.hasPrefix("-") {
            s.displayValue = String(s.displayValue.dropFirst())
        } else {
            s.displayValue = "-" + s.displayValue
        }
        emit(s)
    }

    private func handlePercentage(emit: @escaping Emitter) {
        var s = state
        guard let value = Double(s.displayValue) else { return }
        s.displayValue = formatResult(value / 100)
        emit(s)
    }

    // MARK: - Evaluation

    private func evaluated(
        state: CalculatorState,
        stored: Double,
        current: Double,
        op: Operation
    ) -> CalculatorState {
        var s = state
        switch op {
        case .add:      s.displayValue = formatResult(stored + current)
        case .subtract: s.displayValue = formatResult(stored - current)
        case .multiply: s.displayValue = formatResult(stored * current)
        case .divide:
            if current == 0 {
                addError(CalculatorError.divisionByZero)
                s.hasError = true
                s.displayValue = "Error"
                s.pendingOperation = nil
                s.storedValue = nil
                s.isNewEntry = true
                return s
            }
            s.displayValue = formatResult(stored / current)
        }
        return s
    }

    // MARK: - Formatting

    private func formatResult(_ value: Double) -> String {
        guard !value.isNaN, !value.isInfinite else { return "Error" }
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1e10 {
            return String(Int(value))
        }
        return String(format: "%.9g", value)
    }
}
