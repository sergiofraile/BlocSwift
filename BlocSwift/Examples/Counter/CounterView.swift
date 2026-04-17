//
//  CounterView.swift
//  BlocProject
//
//  Created by Sergio Fraile on 28/04/2025.
//

import Bloc
import SwiftUI

struct CounterView: View {
    let counterBloc = BlocRegistry.resolve(CounterBloc.self)
    
    @State private var animateIncrement = false
    @State private var animateDecrement = false
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.15),
                    Color(red: 0.1, green: 0.15, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }
            
            VStack(spacing: Theme.Spacing.huge) {
                Spacer()
                
                // Hydration badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "externaldrive.fill")
                        .font(Theme.Font.tiny(.semibold))
                    Text("HydratedBloc — state persists across launches")
                        .font(Theme.Font.caption(.medium, .monospaced))
                }
                .foregroundColor(.cyan.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Capsule().fill(Color.cyan.opacity(0.1)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.25), lineWidth: 1))

                // Counter display
                VStack(spacing: Theme.Spacing.md) {
                    Text("COUNTER")
                        .font(Theme.Font.body(.semibold, .monospaced))
                        .tracking(6)
                        .foregroundColor(.cyan.opacity(0.7))
                    
                    Text("\(counterBloc.state)")
                        .font(Theme.Font.display(96, weight: .thin, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .padding(.vertical, Theme.Spacing.xxl)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: counterBloc.state)
                }
                .padding(.vertical, Theme.Spacing.huge)
                .padding(.horizontal, 60)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.huge)
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.huge)
                                .stroke(
                                    LinearGradient(
                                        colors: [Theme.Palette.borderStrong, .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                
                Spacer()
                
                // Control buttons
                HStack(spacing: Theme.Spacing.huge) {
                    // Decrement button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            animateDecrement = true
                        }
                        counterBloc.send(.decrement)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            animateDecrement = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.9, green: 0.3, blue: 0.4), Color(red: 0.7, green: 0.2, blue: 0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(red: 0.9, green: 0.3, blue: 0.4).opacity(0.4), radius: 12, y: 6)
                            
                            Image(systemName: "minus")
                                .font(Theme.Font.display(28, weight: .bold))
                                .foregroundColor(Theme.Palette.textPrimary)
                        }
                        .scaleEffect(animateDecrement ? 0.9 : 1.0)
                    }
                    .buttonStyle(.plain)
                    
                    // Increment button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            animateIncrement = true
                        }
                        counterBloc.send(.increment)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            animateIncrement = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.3, green: 0.8, blue: 0.7), Color(red: 0.2, green: 0.6, blue: 0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.4), radius: 12, y: 6)
                            
                            Image(systemName: "plus")
                                .font(Theme.Font.display(28, weight: .bold))
                                .foregroundColor(Theme.Palette.textPrimary)
                        }
                        .scaleEffect(animateIncrement ? 0.9 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
                
                // Reset buttons
                VStack(spacing: 10) {
                    Button(action: { counterBloc.send(.reset) }) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(Theme.Font.body(.semibold))
                            Text("Reset (persists 0)")
                                .font(Theme.Font.body(.semibold, .rounded))
                        }
                        .foregroundColor(Theme.Palette.textSecondary)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Theme.Palette.surfaceMedium)
                                .overlay(Capsule().stroke(Theme.Palette.borderStrong, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Sends .reset event → emits 0 → 0 is also written to UserDefaults")

                    Button(action: { counterBloc.resetToInitialState() }) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "externaldrive.badge.minus")
                                .font(Theme.Font.body(.semibold))
                            Text("Clear Stored State + Reset")
                                .font(Theme.Font.body(.semibold, .rounded))
                        }
                        .foregroundColor(.cyan.opacity(0.85))
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.08))
                                .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Calls resetToInitialState(): deletes the UserDefaults key, then emits 0 immediately")

                    Text("Increment, then quit and relaunch — the count is restored from UserDefaults.")
                        .font(Theme.Font.caption(.regular, .rounded))
                        .foregroundColor(Theme.Palette.textQuaternary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Counter")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CounterView()
    }
}
