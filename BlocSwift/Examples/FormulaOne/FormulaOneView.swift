//
//  FormulaOneView.swift
//  BlocProject
//
//  Created by Sergio Fraile on 24/06/2025.
//

import Bloc
import SwiftUI

struct FormulaOneView: View {
    
    let formulaOneBloc = BlocRegistry.resolve(FormulaOneBloc.self)
    
    var body: some View {
        ZStack {
            // Dark racing-inspired background — F1 accent: red
            Color(red: 0.08, green: 0.08, blue: 0.1)
                .ignoresSafeArea()
            
            // Subtle checkered pattern accent
            GeometryReader { geometry in
                Path { path in
                    let stripeWidth: CGFloat = 40
                    for i in stride(from: 0, to: geometry.size.width + 200, by: stripeWidth * 2) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i - 100, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: i - 100 + stripeWidth, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: i + stripeWidth, y: 0))
                        path.closeSubpath()
                    }
                }
                .fill(Theme.Palette.surfaceUltraSubtle)
            }
            .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.xl) {
                switch formulaOneBloc.state {
                case .initial:
                    initialStateView
                case .loading:
                    loadingView
                case .loaded(let drivers):
                    driversListView(drivers: drivers)
                case .error(let error):
                    errorView(error: error)
                }
            }
        }
        .navigationTitle("Driver's Championship")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.1), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Initial State
    private var initialStateView: some View {
        VStack(spacing: Theme.Spacing.xxxl) {
            // F1 Logo/Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.7, green: 0.05, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .red.opacity(0.4), radius: 20, y: 10)
                
                Text("F1")
                    .font(Theme.Font.display(44, weight: .black, design: .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
            }
            
            VStack(spacing: Theme.Spacing.md) {
                Text("FORMULA 1")
                    .font(Theme.Font.callout(.bold))
                    .tracking(8)
                    .foregroundColor(.gray)
                
                Text("Driver's Championship")
                    .font(Theme.Font.title(.bold, .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
            }
            
            Button(action: {
                formulaOneBloc.send(.loadChampionship)
            }) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "flag.checkered")
                        .font(Theme.Font.headline(.semibold))
                    Text("Load Championship")
                        .font(Theme.Font.subhead(.semibold, .rounded))
                }
                .foregroundColor(Theme.Palette.textPrimary)
                .padding(.horizontal, Theme.Spacing.xxxl)
                .padding(.vertical, Theme.Spacing.lg)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.1, blue: 0.1), Color(red: 0.75, green: 0.05, blue: 0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .red.opacity(0.4), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.xxl) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
            }
            
            Text("Loading Championship...")
                .font(Theme.Font.subhead(.medium, .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Drivers List
    @ViewBuilder
    private func driversListView(drivers: [DriverChampionship]) -> some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(Array(drivers.enumerated()), id: \.element.id) { index, driver in
                    driverCard(driver: driver, position: index + 1)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    formulaOneBloc.send(.clear)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(Theme.Font.display(20))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Driver Card
    private func driverCard(driver: DriverChampionship, position: Int) -> some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Position badge
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(positionColor(position))
                    .frame(width: 44, height: 44)
                
                Text("\(position)")
                    .font(Theme.Font.headline(.bold, .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
            }
            
            // Driver info
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("\(driver.driver.name) \(driver.driver.surname)")
                    .font(Theme.Font.subhead(.semibold, .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
                
                HStack(spacing: Theme.Spacing.sm) {
                    Text("#\(driver.driver.number)")
                        .font(Theme.Font.footnote(.bold, .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(driver.team.teamName)
                        .font(Theme.Font.footnote(.medium))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Points
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                Text("\(driver.points)")
                    .font(Theme.Font.title3(.bold, .rounded))
                    .foregroundColor(Theme.Palette.textPrimary)
                Text("PTS")
                    .font(Theme.Font.tiny(.semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                .fill(Theme.Palette.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                        .stroke(Theme.Palette.border, lineWidth: 1)
                )
        )
    }
    
    private func positionColor(_ position: Int) -> LinearGradient {
        switch position {
        case 1:
            return LinearGradient(colors: [Color(red: 1.0, green: 0.84, blue: 0), Color(red: 0.85, green: 0.65, blue: 0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2:
            return LinearGradient(colors: [Color(red: 0.75, green: 0.75, blue: 0.8), Color(red: 0.55, green: 0.55, blue: 0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3:
            return LinearGradient(colors: [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.6, green: 0.35, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color(red: 0.25, green: 0.25, blue: 0.3), Color(red: 0.2, green: 0.2, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    // MARK: - Error State
    private func errorView(error: Error) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Theme.Font.display(48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(Theme.Font.display(20, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text(error.localizedDescription)
                .font(Theme.Font.callout())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.huge)
            
            Button(action: {
                formulaOneBloc.send(.loadChampionship)
            }) {
                Text("Try Again")
                    .font(Theme.Font.callout(.semibold))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        FormulaOneView()
    }
}
