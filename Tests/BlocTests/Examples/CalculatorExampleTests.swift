// CalculatorExampleTests.swift
//
// Faithful inline replica of the Calculator example from BlocSwift/Examples/Calculator.
//
// CalculatorBloc is a good demonstration that even a multi-handler, error-emitting
// Bloc remains straightforward to test: create the Bloc, send events, assert on
// `state.displayValue`. The lifecycle log from the real app is omitted here as it
// is a display-only concern and does not affect state.

import Testing
import Combine
@testable import Bloc

// MARK: - Types (mirrors CalculatorEvent.swift / CalculatorState.swift)

private enum Operation: String, Hashable, CaseIterable {
    case add = "+", subtract = "−", multiply = "×", divide = "÷"
}

private enum CalculatorEvent: BlocEvent {
    case digit(Int)
    case operation(Operation)
    case equals
    case clear
    case delete
    case decimal
    case toggleSign
    case percentage
}

private struct CalculatorState: BlocState {
    var displayValue: String
    var storedValue: Double?
    var pendingOperation: Operation?
    var isNewEntry: Bool
    var hasError: Bool

    var currentDoubleValue: Double { Double(displayValue) ?? 0 }

    static let initial = CalculatorState(
        displayValue: "0", storedValue: nil,
        pendingOperation: nil, isNewEntry: false, hasError: false
    )
}

private enum CalculatorError: Error { case divisionByZero }

// MARK: - Inline replica of CalculatorBloc (without BlocLifecycleLog)

@MainActor
private class CalculatorBloc: Bloc<CalculatorState, CalculatorEvent> {

    init() { super.init(initialState: .initial) }

    override func mapEventToState(event: CalculatorEvent, emit: @escaping Emitter) {
        switch event {
        case .digit(let d):       handleDigit(d, emit: emit)
        case .operation(let op):  handleOperation(op, emit: emit)
        case .equals:             handleEquals(emit: emit)
        case .clear:              emit(.initial)
        case .delete:             handleDelete(emit: emit)
        case .decimal:            handleDecimal(emit: emit)
        case .toggleSign:         handleToggleSign(emit: emit)
        case .percentage:         handlePercentage(emit: emit)
        }
    }

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
        s.displayValue = s.displayValue.count > 1 ? String(s.displayValue.dropLast()) : "0"
        if s.displayValue == "-" { s.displayValue = "0" }
        emit(s)
    }

    private func handleDecimal(emit: @escaping Emitter) {
        var s = state
        if s.isNewEntry { s.displayValue = "0."; s.isNewEntry = false }
        else if !s.displayValue.contains(".") { s.displayValue += "." }
        emit(s)
    }

    private func handleToggleSign(emit: @escaping Emitter) {
        var s = state
        guard s.displayValue != "0", !s.hasError else { return }
        s.displayValue = s.displayValue.hasPrefix("-")
            ? String(s.displayValue.dropFirst())
            : "-" + s.displayValue
        emit(s)
    }

    private func handlePercentage(emit: @escaping Emitter) {
        var s = state
        guard let value = Double(s.displayValue) else { return }
        s.displayValue = formatResult(value / 100)
        emit(s)
    }

    private func evaluated(state: CalculatorState, stored: Double, current: Double, op: Operation) -> CalculatorState {
        var s = state
        switch op {
        case .add:      s.displayValue = formatResult(stored + current)
        case .subtract: s.displayValue = formatResult(stored - current)
        case .multiply: s.displayValue = formatResult(stored * current)
        case .divide:
            if current == 0 {
                addError(CalculatorError.divisionByZero)
                s.hasError = true; s.displayValue = "Error"
                s.pendingOperation = nil; s.storedValue = nil; s.isNewEntry = true
                return s
            }
            s.displayValue = formatResult(stored / current)
        }
        return s
    }

    private func formatResult(_ value: Double) -> String {
        guard !value.isNaN, !value.isInfinite else { return "Error" }
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1e10 {
            return String(Int(value))
        }
        return String(format: "%.9g", value)
    }
}

// MARK: - Tests

@MainActor
struct CalculatorExampleTests {

    @Test("CalculatorBloc starts showing '0'")
    func initialDisplayIsZero() {
        let bloc = CalculatorBloc()
        #expect(bloc.state.displayValue == "0")
        #expect(!bloc.state.hasError)
    }

    @Test("Typing digits builds the display string")
    func digitEventsAppendToDisplay() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(4))
        bloc.send(.digit(2))
        #expect(bloc.state.displayValue == "42")
    }

    @Test("Addition: 3 + 4 = 7")
    func addition() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(3))
        bloc.send(.operation(.add))
        bloc.send(.digit(4))
        bloc.send(.equals)
        #expect(bloc.state.displayValue == "7")
    }

    @Test("Subtraction: 10 − 3 = 7")
    func subtraction() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(1))
        bloc.send(.digit(0))
        bloc.send(.operation(.subtract))
        bloc.send(.digit(3))
        bloc.send(.equals)
        #expect(bloc.state.displayValue == "7")
    }

    @Test("Multiplication: 6 × 7 = 42")
    func multiplication() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(6))
        bloc.send(.operation(.multiply))
        bloc.send(.digit(7))
        bloc.send(.equals)
        #expect(bloc.state.displayValue == "42")
    }

    @Test("Division: 20 ÷ 4 = 5")
    func division() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(2))
        bloc.send(.digit(0))
        bloc.send(.operation(.divide))
        bloc.send(.digit(4))
        bloc.send(.equals)
        #expect(bloc.state.displayValue == "5")
    }

    @Test("Division by zero shows 'Error' and emits an error on errorsPublisher")
    func divisionByZeroShowsErrorState() {
        let bloc = CalculatorBloc()
        var errors: [Error] = []
        var cancellables = Set<AnyCancellable>()
        bloc.errorsPublisher.sink { errors.append($0) }.store(in: &cancellables)

        bloc.send(.digit(9))
        bloc.send(.operation(.divide))
        bloc.send(.digit(0))
        bloc.send(.equals)

        #expect(bloc.state.displayValue == "Error")
        #expect(bloc.state.hasError)
        #expect(errors.count == 1)
        #expect(errors.first is CalculatorError)
        withExtendedLifetime(cancellables) {}
    }

    @Test("Clear resets the display to '0'")
    func clearResetsDisplay() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(9))
        bloc.send(.digit(9))
        bloc.send(.clear)
        #expect(bloc.state.displayValue == "0")
        #expect(!bloc.state.hasError)
    }

    @Test("Toggle sign negates and then restores the displayed value")
    func toggleSignNegatesValue() {
        let bloc = CalculatorBloc()
        bloc.send(.digit(5))
        bloc.send(.toggleSign)
        #expect(bloc.state.displayValue == "-5")
        bloc.send(.toggleSign)
        #expect(bloc.state.displayValue == "5")
    }
}
