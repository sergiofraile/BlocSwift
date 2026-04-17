//
//  TimerView.swift
//  BlocSwift
//

import Bloc
import SwiftUI

struct TimerView: View {

    let timerCubit = BlocRegistry.resolve(TimerCubit.self)

    @State private var animateRing = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()
                cubitBadge
                    .padding(.bottom, Theme.Spacing.xxl)

                clockFace
                    .padding(.bottom, Theme.Spacing.huge)

                controls
                    .padding(.bottom, Theme.Spacing.xxl)

                Spacer()

                footerNote
                    .padding(.bottom, Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.xxl)
        }
        .navigationTitle("Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.06),
                    Color(red: 0.03, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient glow that pulses while running
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            timerCubit.state.isRunning
                                ? Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.15)
                                : Color.clear,
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .blur(radius: 60)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: timerCubit.state.isRunning)
        }
    }

    // MARK: - Cubit Badge

    private var cubitBadge: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "bolt.fill")
                .font(Theme.Font.tiny(.semibold))
            Text("Cubit — no events, direct method calls")
                .font(Theme.Font.caption(.medium, .monospaced))
        }
        .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.8))
        .padding(.horizontal, 14)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Capsule().fill(Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.1)))
        .overlay(Capsule().stroke(Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.25), lineWidth: 1))
    }

    // MARK: - Clock Face

    private var clockFace: some View {
        ZStack {
            // Outer ring that animates while running
            Circle()
                .stroke(
                    AngularGradient(
                        colors: timerCubit.state.isRunning
                            ? [
                                Color(red: 0.1, green: 0.9, blue: 0.55),
                                Color(red: 0.05, green: 0.6, blue: 0.4),
                                Color.clear,
                                Color.clear
                              ]
                            : [Color.white.opacity(0.06)],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(animateRing ? 360 : 0))
                .animation(
                    timerCubit.state.isRunning
                        ? .linear(duration: 4).repeatForever(autoreverses: false)
                        : .default,
                    value: animateRing
                )
                .onChange(of: timerCubit.state.isRunning) { _, running in
                    if running { animateRing = true } else { animateRing = false }
                }

            // Inner face
            Circle()
                .fill(.ultraThinMaterial.opacity(0.25))
                .frame(width: 280, height: 280)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            // Time digits
            VStack(spacing: 0) {
                // MM:SS large
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(timerCubit.state.minutesDisplay)
                        .contentTransition(.numericText())
                    Text(":")
                        .opacity(timerCubit.state.isRunning ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: timerCubit.state.isRunning)
                    Text(timerCubit.state.secondsDisplay)
                        .contentTransition(.numericText())
                }
                .font(.system(size: 68, weight: .thin, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .animation(.spring(response: 0.25), value: timerCubit.state.secondsDisplay)

                // .CS centiseconds
                HStack(spacing: 2) {
                    Text(".")
                    Text(timerCubit.state.centisecondsDisplay)
                        .contentTransition(.numericText())
                }
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
                .animation(.spring(response: 0.15), value: timerCubit.state.centisecondsDisplay)
                .padding(.top, -6)
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            // Reset
            Button(action: { timerCubit.reset() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    Image(systemName: "arrow.counterclockwise")
                        .font(Theme.Font.body(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .disabled(timerCubit.state.elapsed == 0 && !timerCubit.state.isRunning)
            .opacity(timerCubit.state.elapsed == 0 && !timerCubit.state.isRunning ? 0.35 : 1)

            // Start / Pause
            Button(action: {
                if timerCubit.state.isRunning {
                    timerCubit.pause()
                } else {
                    timerCubit.start()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: timerCubit.state.isRunning
                                    ? [Color(red: 1.0, green: 0.7, blue: 0.2), Color(red: 0.9, green: 0.5, blue: 0.1)]
                                    : [Color(red: 0.1, green: 0.85, blue: 0.55), Color(red: 0.05, green: 0.65, blue: 0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(
                            color: timerCubit.state.isRunning
                                ? Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.5)
                                : Color(red: 0.1, green: 0.85, blue: 0.55).opacity(0.5),
                            radius: 18,
                            y: 6
                        )
                        .animation(.spring(response: 0.35), value: timerCubit.state.isRunning)

                    Image(systemName: timerCubit.state.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: timerCubit.state.isRunning ? 0 : 2)
                        .animation(.spring(response: 0.25), value: timerCubit.state.isRunning)
                }
            }
            .buttonStyle(.plain)

            // Placeholder to balance layout
            Circle()
                .fill(Color.clear)
                .frame(width: 60, height: 60)
        }
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.sm) {
                methodCallChip("timerCubit.start()")
                methodCallChip("timerCubit.pause()")
                methodCallChip("timerCubit.reset()")
            }
            Text("State managed by TimerCubit — no events, no handlers, no transformers.")
                .font(Theme.Font.caption(.regular, .rounded))
                .foregroundColor(Theme.Palette.textQuaternary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
    }

    private func methodCallChip(_ label: String) -> some View {
        Text(label)
            .font(Theme.Font.tiny(.medium, .monospaced))
            .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.6).opacity(0.75))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.18), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        TimerView()
    }
}
