//
//  CalculatorState.swift
//  BlocSwift
//

/// The state managed by ``CalculatorBloc``.
struct CalculatorState: Equatable {

    /// The formatted string shown in the calculator display.
    var displayValue: String

    /// The left-hand operand stored when the user presses an operation button.
    var storedValue: Double?

    /// The pending binary operation, waiting for the right-hand operand.
    var pendingOperation: Operation?

    /// When `true`, the next digit press replaces the display instead of appending.
    var isNewEntry: Bool

    /// Set to `true` after a division-by-zero error.
    var hasError: Bool

    /// The numeric value of ``displayValue``, or `0` for error/non-numeric displays.
    var currentDoubleValue: Double {
        Double(displayValue) ?? 0
    }

    static let initial = CalculatorState(
        displayValue: "0",
        storedValue: nil,
        pendingOperation: nil,
        isNewEntry: false,
        hasError: false
    )
}
