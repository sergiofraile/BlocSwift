//
//  ScoreView.swift
//  BlocProject
//

import Bloc
import SwiftUI

// MARK: - Tier helpers

private enum Tier: String, Equatable {
    case bronze   = "Bronze"
    case silver   = "Silver"
    case gold     = "Gold"
    case platinum = "Platinum"

    init(score: Int) {
        switch score {
        case 0..<10:  self = .bronze
        case 10..<20: self = .silver
        case 20..<30: self = .gold
        default:      self = .platinum
        }
    }

    var color: Color {
        switch self {
        case .bronze:   return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver:   return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .gold:     return Color(red: 0.95, green: 0.75, blue: 0.10)
        case .platinum: return Color(red: 0.30, green: 0.90, blue: 0.95)
        }
    }

    /// Two-stop gradient used for the large score numeral.
    var gradientColors: [Color] {
        switch self {
        case .bronze:
            return [Color(red: 1.00, green: 0.85, blue: 0.60),
                    Color(red: 0.70, green: 0.35, blue: 0.05)]
        case .silver:
            return [Color(red: 1.00, green: 1.00, blue: 1.00),
                    Color(red: 0.55, green: 0.60, blue: 0.70)]
        case .gold:
            return [Color(red: 1.00, green: 0.95, blue: 0.50),
                    Color(red: 0.85, green: 0.55, blue: 0.00)]
        case .platinum:
            return [Color(red: 0.75, green: 1.00, blue: 1.00),
                    Color(red: 0.10, green: 0.65, blue: 0.90)]
        }
    }

    var symbolName: String {
        switch self {
        case .bronze:   return "medal"
        case .silver:   return "medal.fill"
        case .gold:     return "trophy.fill"
        case .platinum: return "crown.fill"
        }
    }
}

// MARK: - ScoreView

/// Demonstrates ``BlocListener``, ``BlocBuilder``, and ``BlocConsumer`` together.
///
/// Three distinct reactive layers are stacked together:
///
/// 1. **`BlocBuilder`** — the score numeral updates on every point via its own
///    explicit `@Observable` subscription, reliable even inside an `@escaping`
///    closure.
///
/// 2. **`BlocListener`** — fires a milestone banner side-effect at every 5-point
///    boundary without rebuilding any content.
///
/// 3. **`BlocConsumer`** — the Tier badge rebuilds only at tier boundaries (every
///    10 pts) **and** triggers a pulse animation as a side effect at the same
///    moment — two behaviours, one component, one subscription.
struct ScoreView: View {

    let scoreBloc = BlocRegistry.resolve(ScoreBloc.self)

    @State private var milestoneText: String? = nil
    @State private var dismissTask: Task<Void, Never>? = nil
    @State private var tierPulse = false

    var body: some View {
        ZStack {
            background

            // BlocListener wraps all content. Its listener closure fires as a
            // side-effect (showing the banner) without rebuilding anything inside.
            BlocListener(ScoreBloc.self,
                listenWhen: { _, new in new > 0 && new % 5 == 0 }
            ) { state in
                showMilestone("🎯 \(state) points!")
            } content: {
                VStack(spacing: 40) {
                    Spacer()
                    featureBadgeRow
                    scoreDisplay
                    tierDisplay
                    Spacer()
                    actionButtons
                }
                .padding(.horizontal, 28)
            }
        }
        .overlay(alignment: .top) {
            if let text = milestoneText {
                milestoneBanner(text)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: milestoneText != nil)
        .navigationTitle("Score Board")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Milestone logic

    private func showMilestone(_ message: String) {
        dismissTask?.cancel()
        withAnimation { milestoneText = message }
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation { milestoneText = nil }
        }
    }

    // MARK: - Sub-views

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.06, blue: 0.10),
                Color(red: 0.10, green: 0.08, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var featureBadgeRow: some View {
        VStack(spacing: 8) {
            featurePill(symbol: "bell.badge.fill",
                        text: "BlocListener — milestone side-effect",
                        color: .orange)
            featurePill(symbol: "square.stack.fill",
                        text: "BlocConsumer — tier rebuild + animation",
                        color: .cyan)
        }
    }

    private func featurePill(symbol: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.10)))
        .overlay(Capsule().stroke(color.opacity(0.25), lineWidth: 1))
    }

    // BlocBuilder gives scoreDisplay its own @Observable subscription so it
    // reliably re-renders inside BlocListener's @escaping content closure.
    private var scoreDisplay: some View {
        BlocBuilder(ScoreBloc.self) { bloc in
            let tier = Tier(score: bloc.state)
            VStack(spacing: 8) {
                Text("SCORE")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .tracking(5)
                    .foregroundColor(.white.opacity(0.5))

                // Numeral gradient shifts with the current tier.
                Text("\(bloc.state)")
                    .font(.system(size: 100, weight: .thin, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: tier.gradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: bloc.state)
                    .animation(.easeInOut(duration: 0.5), value: tier)

                Text("Next milestone at \(nextMilestone(for: bloc.state)) pts")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [tier.color.opacity(0.45), tier.color.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: tier.color.opacity(0.25), radius: 16, y: 6)
            )
            .animation(.easeInOut(duration: 0.5), value: tier)
        }
    }

    private func nextMilestone(for score: Int) -> Int {
        score + (5 - score % 5)
    }

    // BlocConsumer: redraws the tier badge only on tier changes (buildWhen) AND
    // fires a pulse animation as a side effect at the same moment (listenWhen).
    private var tierDisplay: some View {
        BlocConsumer(ScoreBloc.self,
            listenWhen: { old, new in Tier(score: old) != Tier(score: new) },
            listener: { _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { tierPulse = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(400))
                    withAnimation(.spring(response: 0.3)) { tierPulse = false }
                }
            },
            buildWhen: { old, new in Tier(score: old) != Tier(score: new) }
        ) { state in
            let tier = Tier(score: state)
            HStack(spacing: 10) {
                Image(systemName: tier.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tier.color, tier.color.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.rawValue)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(tier.color)
                    Text(tierSubtitle(tier))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(tier.color.opacity(tierPulse ? 0.22 : 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(tier.color.opacity(tierPulse ? 0.65 : 0.30), lineWidth: tierPulse ? 1.5 : 1)
                    )
                    .shadow(color: tier.color.opacity(tierPulse ? 0.45 : 0), radius: 14, y: 4)
            )
            .scaleEffect(tierPulse ? 1.06 : 1.0)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.4), value: tier.rawValue)
        }
    }

    private func tierSubtitle(_ tier: Tier) -> String {
        switch tier {
        case .bronze:   return "Reach 10 pts to advance"
        case .silver:   return "Reach 20 pts to advance"
        case .gold:     return "Reach 30 pts to advance"
        case .platinum: return "Maximum tier reached"
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                scoreBloc.send(.addPoint)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Score!")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: 280)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.50, green: 0.20, blue: 0.90),
                                         Color(red: 0.30, green: 0.10, blue: 0.70)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
                )
            }
            .buttonStyle(.plain)

            Button {
                scoreBloc.send(.reset)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Reset")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            Text("Every 5 pts → BlocListener fires. Tier badge: BlocConsumer rebuilds + animates at 10, 20, 30 pts.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.30))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, 4)
        }
    }

    private func milestoneBanner(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color(red: 0.18, green: 0.14, blue: 0.28))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.5), .orange.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .orange.opacity(0.3), radius: 12, y: 4)
        )
    }
}

#Preview {
    NavigationStack {
        ScoreView()
    }
}
