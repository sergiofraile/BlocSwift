//
//  HeartbeatView.swift
//  BlocSwift
//
//  Demonstrates **scoped Bloc lifecycle management**.
//
//  HeartbeatBloc is NOT registered in BlocProvider — it is created directly
//  using @State so its lifetime is tied to this view. onAppear starts the
//  ticker; onDisappear calls close(), which cancels the async task immediately
//  and fires onClose(). Navigate away and back to see a fresh Bloc start from zero.
//

import Bloc
import SwiftUI

// MARK: - Root View

struct HeartbeatView: View {

    /// The Bloc is owned by this view, not the global BlocProvider.
    /// A new instance is created each time the view appears from scratch.
    @State private var bloc = HeartbeatBloc()

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showingLog = false

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                MonitorPanel(bloc: bloc, onNewSession: newSession)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        MonitorPanel(bloc: bloc, onNewSession: newSession)
                            .frame(width: min(380, geo.size.width * 0.5))

                        Divider().background(Theme.Palette.divider)

                        LifecycleLogPanel(bloc: bloc)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.10),
                    Color(red: 0.06, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .safeAreaInset(edge: .top, spacing: 0) {
            LifecycleFeatureBanner()
        }
        .navigationTitle("Heartbeat — Scoped Lifecycle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.04, green: 0.06, blue: 0.10), for: .navigationBar)
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
            HeartbeatLogSheet(bloc: bloc)
        }
        .onAppear {
            if !bloc.state.isRunning && !bloc.isClosed {
                bloc.send(.start)
            }
        }
        .onDisappear {
            bloc.close()
        }
    }

    private func newSession() {
        bloc.close()
        bloc = HeartbeatBloc()
        bloc.send(.start)
    }
}

// MARK: - Monitor Panel

private struct MonitorPanel: View {
    let bloc: HeartbeatBloc
    let onNewSession: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var accentColor: Color { bloc.isClosed ? .orange : Color(red: 0.3, green: 0.85, blue: 0.6) }

    var body: some View {
        if verticalSizeClass == .compact {
            landscapeLayout
        } else {
            portraitLayout
        }
    }

    // MARK: Portrait

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            PulseRing(tickCount: bloc.state.tickCount, isClosed: bloc.isClosed)
                .frame(width: 200, height: 200)
            Spacer().frame(height: Theme.Spacing.xxxl)
            sessionStats
            Spacer().frame(height: Theme.Spacing.huge)
            explanationCard
            Spacer().frame(height: Theme.Spacing.xxl)
            newSessionButton
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    // MARK: Landscape

    private var landscapeLayout: some View {
        HStack(spacing: Theme.Spacing.xxxl) {
            // Scaled-down ring
            PulseRing(tickCount: bloc.state.tickCount, isClosed: bloc.isClosed)
                .frame(width: 200, height: 200)
                .scaleEffect(0.6)
                .frame(width: 120, height: 120)

            // Stats + button (no explanation card — not enough vertical space)
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                sessionStats
                Spacer()
                newSessionButton
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // MARK: Shared sub-views

    private var sessionStats: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(bloc.isClosed ? "CLOSED" : bloc.state.formattedDuration)
                .font(Theme.Font.display(48, weight: .thin, design: .monospaced))
                .foregroundColor(bloc.isClosed ? .orange : Theme.Palette.textPrimary)
                .animation(.easeInOut(duration: 0.3), value: bloc.isClosed)
                .contentTransition(.numericText())

            Text(bloc.isClosed
                 ? "Navigate away to close automatically"
                 : "\(bloc.state.tickCount) tick\(bloc.state.tickCount == 1 ? "" : "s")")
                .font(Theme.Font.body(.medium, .rounded))
                .foregroundColor(Theme.Palette.textQuaternary)
        }
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Scoped Bloc Pattern", systemImage: "info.circle")
                .font(Theme.Font.footnote(.semibold, .rounded))
                .foregroundColor(Theme.Palette.textTertiary)

            Text("This Bloc is **not** in BlocProvider. It is owned by the view via `@State` — created on appear, closed on disappear. Navigate away to trigger `close()` automatically, or tap New Session below.")
                .font(Theme.Font.caption(.regular, .rounded))
                .foregroundColor(Theme.Palette.textQuaternary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .fill(Theme.Palette.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
        )
        .padding(.horizontal, 28)
    }

    private var newSessionButton: some View {
        Button(action: onNewSession) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "arrow.clockwise.circle.fill")
                Text("New Session")
                    .fontWeight(.semibold)
            }
            .font(Theme.Font.callout(.regular, .rounded))
            .foregroundColor(Theme.Palette.textPrimary)
            .padding(.horizontal, Theme.Spacing.xxl)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.7, blue: 1.0),
                                Color(red: 0.1, green: 0.5, blue: 0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(red: 0.1, green: 0.5, blue: 0.9).opacity(0.4), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pulse Ring Animation

private struct PulseRing: View {
    let tickCount: Int
    let isClosed: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer ripple rings — animate on each tick
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        isClosed ? Color.orange.opacity(0.15) : Color(red: 0.3, green: 0.85, blue: 0.6).opacity(0.2 - Double(i) * 0.05),
                        lineWidth: 1.5
                    )
                    .scaleEffect(pulse ? 1.0 + CGFloat(i + 1) * 0.25 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.9).delay(Double(i) * 0.15),
                        value: pulse
                    )
            }

            // Core circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: isClosed
                            ? [Color.orange.opacity(0.3), Color.orange.opacity(0.05)]
                            : [Color(red: 0.2, green: 0.85, blue: 0.55).opacity(0.4),
                               Color(red: 0.1, green: 0.5, blue: 0.35).opacity(0.1)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isClosed ? Color.orange.opacity(0.5) : Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.6),
                            lineWidth: 1.5
                        )
                )
                .scaleEffect(pulse ? 1.04 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: pulse)

            // Icon
            Image(systemName: isClosed ? "xmark.circle" : "waveform.path.ecg")
                .font(Theme.Font.display(32, weight: .thin))
                .foregroundColor(isClosed ? .orange.opacity(0.7) : Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.8))
                .animation(.easeInOut(duration: 0.3), value: isClosed)
        }
        .onChange(of: tickCount) { _, _ in
            guard !isClosed else { return }
            pulse = false
            withAnimation { pulse = true }
        }
    }
}

// MARK: - Lifecycle Log Panel

private struct LifecycleLogPanel: View {
    let bloc: HeartbeatBloc

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

                Button {
                    withAnimation { log.clear() }
                } label: {
                    Image(systemName: "trash")
                        .font(Theme.Font.body(.medium))
                        .foregroundColor(Theme.Palette.textDisabled)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Palette.surfaceUltraSubtle)

            Divider().background(Theme.Palette.divider)

            if log.entries.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(log.entries) { entry in
                                LogRow(entry: entry)
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
            Text("Starting…")
                .font(Theme.Font.callout(.medium, .rounded))
                .foregroundColor(Theme.Palette.textDisabled)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Log Row

private struct LogRow: View {
    let entry: BlocLifecycleLog.LogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: entry.kind.symbol)
                    .font(Theme.Font.micro(.bold))
                Text(entry.kind.label)
                    .font(Theme.Font.micro(.bold, .monospaced))
            }
            .foregroundColor(entry.kind.color)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, Theme.Spacing.xxxs)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.xs).fill(entry.kind.color.opacity(0.12)))
            .frame(width: 90, alignment: .leading)

            Text(entry.message)
                .font(Theme.Font.footnote(.regular, .monospaced))
                .foregroundColor(Theme.Palette.textPrimary.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(entry.timestamp.logTimestamp)
                .font(Theme.Font.tiny(.regular, .monospaced))
                .foregroundColor(Theme.Palette.textDisabled)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(
            entry.kind == .close ? Color.orange.opacity(0.06) : Color.clear
        )
        .overlay(alignment: .bottom) {
            Divider().background(Theme.Palette.surfaceSubtle)
        }
    }
}

// MARK: - Feature Disclaimer Banner

private struct LifecycleFeatureBanner: View {
    @State private var expanded = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Image(systemName: "xmark.circle.fill")
                    .font(Theme.Font.headline(.medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.85, blue: 0.6), Color(red: 0.1, green: 0.65, blue: 0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                if expanded {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Demonstrates: close() — Lifecycle Management")
                            .font(Theme.Font.footnote(.semibold, .rounded))
                            .foregroundColor(Theme.Palette.textPrimary.opacity(0.9))

                        Text("This Bloc is **not** in BlocProvider. It is scoped to this screen via `@State`. Navigate away and the Bloc is closed automatically via `onDisappear { bloc.close() }`. Return to see a fresh Bloc start from zero. Tap **New Session** to close and recreate the Bloc inline.")
                            .font(Theme.Font.caption(.regular, .rounded))
                            .foregroundColor(Theme.Palette.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("close() — Lifecycle Management")
                        .font(Theme.Font.footnote(.semibold, .rounded))
                        .foregroundColor(Theme.Palette.textTertiary)
                    Spacer()
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { expanded.toggle() }
                } label: {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(Theme.Font.caption(.semibold))
                        .foregroundColor(Theme.Palette.textQuaternary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)

            Divider().background(Theme.Palette.divider)
        }
        .background(
            Color(red: 0.1, green: 0.2, blue: 0.15).opacity(0.85)
                .overlay(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.85, blue: 0.6).opacity(0.08), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
        )
    }
}

// MARK: - Log Sheet (compact/portrait)

private struct HeartbeatLogSheet: View {
    let bloc: HeartbeatBloc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LifecycleLogPanel(bloc: bloc)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.06, blue: 0.10),
                            Color(red: 0.06, green: 0.04, blue: 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .navigationTitle("Lifecycle Log")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color(red: 0.04, green: 0.06, blue: 0.10), for: .navigationBar)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        HeartbeatView()
    }
    .frame(width: 800, height: 600)
}
