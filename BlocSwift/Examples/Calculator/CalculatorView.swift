//
//  CalculatorView.swift
//  BlocSwift
//

import Bloc
import SwiftUI

// MARK: - Root View

struct CalculatorView: View {
    let bloc = BlocRegistry.resolve(CalculatorBloc.self)

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingLog = false

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                CalculatorPadView(bloc: bloc)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        CalculatorPadView(bloc: bloc)
                            .frame(width: min(360, geo.size.width * 0.5))

                        Divider()
                            .background(Theme.Palette.divider)

                        LifecycleLogView(bloc: bloc)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.07, green: 0.07, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .navigationTitle("Calculator — Lifecycle Hooks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.08), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if horizontalSizeClass == .compact {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLog = true
                    } label: {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundColor(Theme.Palette.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLog) {
            LogSheet(bloc: bloc)
        }
    }
}

private struct LogSheet: View {
    let bloc: CalculatorBloc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LifecycleLogView(bloc: bloc)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.05, blue: 0.08),
                            Color(red: 0.07, green: 0.07, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .navigationTitle("Lifecycle Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(red: 0.05, green: 0.05, blue: 0.08), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
    }
}

// MARK: - Calculator Pad

private struct CalculatorPadView: View {
    let bloc: CalculatorBloc

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }
    private var buttonSpacing: CGFloat { isLandscape ? 5 : 10 }
    private var vPad: CGFloat { isLandscape ? Theme.Spacing.xs : Theme.Spacing.xxl }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                DisplayView(state: bloc.state)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, vPad)
                .padding(.bottom, isLandscape ? Theme.Spacing.xxs : Theme.Spacing.lg)

            VStack(spacing: buttonSpacing) {
                // Row 1: AC, +/−, %, ÷
                HStack(spacing: buttonSpacing) {
                    CalcButton(label: bloc.state.hasError ? "AC" : "AC", style: .function) {
                        bloc.send(.clear)
                    }
                    CalcButton(label: "+/−", style: .function) { bloc.send(.toggleSign) }
                    CalcButton(label: "%",   style: .function) { bloc.send(.percentage) }
                    CalcButton(label: "÷",   style: .operation,
                               isActive: bloc.state.pendingOperation == .divide) {
                        bloc.send(.operation(.divide))
                    }
                }
                // Row 2: 7, 8, 9, ×
                HStack(spacing: buttonSpacing) {
                    CalcButton(label: "7", style: .digit) { bloc.send(.digit(7)) }
                    CalcButton(label: "8", style: .digit) { bloc.send(.digit(8)) }
                    CalcButton(label: "9", style: .digit) { bloc.send(.digit(9)) }
                    CalcButton(label: "×", style: .operation,
                               isActive: bloc.state.pendingOperation == .multiply) {
                        bloc.send(.operation(.multiply))
                    }
                }
                // Row 3: 4, 5, 6, −
                HStack(spacing: buttonSpacing) {
                    CalcButton(label: "4", style: .digit) { bloc.send(.digit(4)) }
                    CalcButton(label: "5", style: .digit) { bloc.send(.digit(5)) }
                    CalcButton(label: "6", style: .digit) { bloc.send(.digit(6)) }
                    CalcButton(label: "−", style: .operation,
                               isActive: bloc.state.pendingOperation == .subtract) {
                        bloc.send(.operation(.subtract))
                    }
                }
                // Row 4: 1, 2, 3, +
                HStack(spacing: buttonSpacing) {
                    CalcButton(label: "1", style: .digit) { bloc.send(.digit(1)) }
                    CalcButton(label: "2", style: .digit) { bloc.send(.digit(2)) }
                    CalcButton(label: "3", style: .digit) { bloc.send(.digit(3)) }
                    CalcButton(label: "+", style: .operation,
                               isActive: bloc.state.pendingOperation == .add) {
                        bloc.send(.operation(.add))
                    }
                }
                // Row 5: 0 (wide), ., ⌫, =
                HStack(spacing: buttonSpacing) {
                    CalcButton(label: "0", style: .digit, wide: true) { bloc.send(.digit(0)) }
                    CalcButton(label: ".", style: .digit)  { bloc.send(.decimal) }
                    CalcButton(label: "⌫", style: .function) { bloc.send(.delete) }
                    CalcButton(label: "=", style: .equals)   { bloc.send(.equals) }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, vPad)
        }
        .opacity(bloc.isClosed ? 0.35 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: bloc.isClosed)

        // Closed overlay — shown when close() has been called
        if bloc.isClosed {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "xmark.circle.fill")
                    .font(Theme.Font.display(40, weight: .thin))
                    .foregroundStyle(.orange)
                Text("Bloc Closed")
                    .font(Theme.Font.headline(.semibold, .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
                Text("send() and emit() are no-ops.\nIn a real app, navigate away or\nreplace the Bloc to continue.")
                    .font(Theme.Font.footnote(.regular, .rounded))
                    .foregroundColor(Theme.Palette.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.xxl)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.xxxl, style: .continuous))
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bloc.isClosed)
    }
}

// MARK: - Display

private struct DisplayView: View {
    let state: CalculatorState

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
            // Pending operation indicator
            HStack {
                Spacer()
                if let op = state.pendingOperation {
                    Text(op.rawValue)
                        .font(Theme.Font.headline(.light, .rounded))
                        .foregroundColor(.orange.opacity(0.8))
                        .transition(.opacity)
                }
            }
            .frame(height: 24)

            // Main display value
            Text(state.displayValue)
                .font(Theme.Font.display(displayFontSize(for: state.displayValue),
                                         weight: .thin, design: .rounded))
                .foregroundStyle(
                    state.hasError
                        ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.white, .white.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.25), value: state.displayValue)
        }
        .padding(verticalSizeClass == .compact ? Theme.Spacing.xs : Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                .fill(Theme.Palette.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
        )
    }

    private func displayFontSize(for value: String) -> CGFloat {
        switch value.count {
        case ..<7:  return 64
        case 7..<10: return 48
        default:     return 36
        }
    }
}

// MARK: - Button

private enum ButtonStyle { case digit, operation, function, equals }

private struct CalcButton: View {
    let label: String
    let style: ButtonStyle
    var isActive: Bool = false
    var wide: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.15)) { isPressed = true }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.2)) { isPressed = false }
            }
        }) {
            Text(label)
                .font(Theme.Font.title3(labelWeight, .rounded))
                .foregroundColor(labelColor)
                .frame(maxWidth: wide ? .infinity : nil)
                .frame(width: wide ? nil : buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                        .fill(fillColor)
                        .shadow(color: shadowColor, radius: isPressed ? 2 : 6, y: isPressed ? 1 : 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                        .stroke(strokeColor, lineWidth: 0.5)
                )
                .scaleEffect(isPressed ? 0.93 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    private var buttonSize: CGFloat { verticalSizeClass == .compact ? 44 : 68 }

    private var fillColor: Color {
        switch style {
        case .digit:
            return Color(red: 0.18, green: 0.18, blue: 0.22)
        case .function:
            return Color(red: 0.28, green: 0.28, blue: 0.32)
        case .operation:
            return isActive
                ? Color(red: 1.0, green: 0.65, blue: 0.2).opacity(0.25)
                : Color(red: 0.95, green: 0.6, blue: 0.1)
        case .equals:
            return Color(red: 0.2, green: 0.75, blue: 0.5)
        }
    }

    private var labelColor: Color {
        switch style {
        case .digit, .equals, .operation: return .white
        case .function: return Color(red: 0.9, green: 0.9, blue: 0.95)
        }
    }

    private var labelWeight: SwiftUI.Font.Weight {
        style == .digit ? .regular : .semibold
    }

    private var strokeColor: Color {
        switch style {
        case .operation: return isActive ? Color.orange.opacity(0.6) : Color.orange.opacity(0.2)
        default:         return Theme.Palette.borderFaint
        }
    }

    private var shadowColor: Color {
        switch style {
        case .equals:    return Color.green.opacity(0.3)
        case .operation: return Color.orange.opacity(0.2)
        default:         return Color.black.opacity(0.3)
        }
    }
}

// MARK: - Lifecycle Log Panel

private struct LifecycleLogView: View {
    let bloc: CalculatorBloc
    @State private var showingCloseConfirm = false

    private var log: BlocLifecycleLog { bloc.lifecycleLog }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("Lifecycle Log")
                            .font(Theme.Font.callout(.semibold, .rounded))
                            .foregroundColor(Theme.Palette.textPrimary)

                        // Status badge
                        HStack(spacing: Theme.Spacing.xxs) {
                            Circle()
                                .fill(bloc.isClosed ? Color.orange : Color.green)
                                .frame(width: 6, height: 6)
                            Text(bloc.isClosed ? "CLOSED" : "ACTIVE")
                                .font(Theme.Font.micro(.bold, .rounded))
                                .foregroundColor(bloc.isClosed ? .orange : .green)
                        }
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, Theme.Spacing.xxxs)
                        .background(
                            Capsule().fill((bloc.isClosed ? Color.orange : Color.green).opacity(0.12))
                        )
                    }
                    Text("\(log.entries.count) events")
                        .font(Theme.Font.caption(.medium, .rounded))
                        .foregroundColor(Theme.Palette.textDisabled)
                }

                Spacer()

                // Legend pills
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach([
                        BlocLifecycleLog.LogEntry.Kind.event,
                        .change,
                        .transition,
                        .error,
                        .close
                    ], id: \.label) { kind in
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: kind.symbol)
                                .font(Theme.Font.micro(.bold))
                            Text(kind.label)
                                .font(Theme.Font.micro(.semibold, .rounded))
                        }
                        .foregroundColor(kind.color)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, Theme.Spacing.xxxs)
                        .background(
                            Capsule().fill(kind.color.opacity(0.12))
                        )
                    }
                }

                // Close bloc button (disabled once already closed)
                Button {
                    showingCloseConfirm = true
                } label: {
                    Image(systemName: "stop.circle")
                        .font(Theme.Font.body(.medium))
                        .foregroundColor(bloc.isClosed ? Theme.Palette.textHint : .orange.opacity(0.7))
                }
                .buttonStyle(.plain)
                .disabled(bloc.isClosed)
                .help("Close this Bloc — demonstrates lifecycle teardown")
                .confirmationDialog(
                    "Close Bloc?",
                    isPresented: $showingCloseConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Close Bloc", role: .destructive) { bloc.close() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Simulates navigating away from a screen with a scoped Bloc. send() and emit() become no-ops, publishers complete, and onClose fires.")
                }

                Button {
                    withAnimation { log.clear() }
                } label: {
                    Image(systemName: "trash")
                        .font(Theme.Font.body(.medium))
                        .foregroundColor(Theme.Palette.textDisabled)
                }
                .buttonStyle(.plain)
                .padding(.leading, Theme.Spacing.xxs)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Palette.surfaceUltraSubtle)

            Divider().background(Theme.Palette.divider)

            // Log entries
            if log.entries.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(log.entries) { entry in
                                LogEntryRow(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.xxs)
                    }
                    .onChange(of: log.entries.count) { _, _ in
                        if let last = log.entries.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(Theme.Font.display(36, weight: .thin))
                .foregroundColor(Theme.Palette.textHint)
            Text("No events yet")
                .font(Theme.Font.callout(.medium, .rounded))
                .foregroundColor(Theme.Palette.textDisabled)
            Text("Tap a button on the calculator\nto watch the lifecycle hooks fire.")
                .font(Theme.Font.footnote(.regular, .rounded))
                .foregroundColor(Theme.Palette.textHint)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {
    let entry: BlocLifecycleLog.LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Kind badge
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: entry.kind.symbol)
                    .font(Theme.Font.micro(.bold))
                Text(entry.kind.label)
                    .font(Theme.Font.micro(.bold, .monospaced))
            }
            .foregroundColor(entry.kind.color)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxxs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xs)
                    .fill(entry.kind.color.opacity(0.12))
            )
            .frame(width: 100, alignment: .leading)

            // Message
            Text(entry.message)
                .font(Theme.Font.footnote(.regular, .monospaced))
                .foregroundColor(Theme.Palette.textPrimary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Timestamp
            Text(entry.timestamp.logTimestamp)
                .font(Theme.Font.tiny(.regular, .monospaced))
                .foregroundColor(Theme.Palette.textDisabled)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            entry.kind == .error  ? Color.red.opacity(0.06)    :
            entry.kind == .close  ? Color.orange.opacity(0.06) : Color.clear
        )
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Palette.surfaceSubtle)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BlocProvider(with: [CalculatorBloc()]) {
            CalculatorView()
        }
    }
    .frame(width: 800, height: 600)
}
