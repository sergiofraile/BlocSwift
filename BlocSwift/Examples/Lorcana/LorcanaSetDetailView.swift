//
//  LorcanaSetDetailView.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Bloc
import SwiftUI

struct LorcanaSetDetailView: View {
    
    let setName: String
    let lorcanaBloc = BlocRegistry.resolve(LorcanaBloc.self)
    
    @State private var setCards: [LorcanaCard] = []
    @State private var isLoading = true
    @State private var error: LorcanaError?
    @State private var hasLoaded = false
    
    private let networkService = LorcanaNetworkService()
    
    var body: some View {
        ZStack {
            // Dark magical background — purple accent
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.08, blue: 0.14),
                    Color(red: 0.10, green: 0.06, blue: 0.16),
                    Color(red: 0.04, green: 0.04, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle orb pattern
            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.purple.opacity(Double.random(in: 0.02...0.06)))
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: -50...geometry.size.width + 50),
                            y: CGFloat.random(in: -50...geometry.size.height + 50)
                        )
                        .blur(radius: 40)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                setHeader
                
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error: error)
                } else if setCards.isEmpty {
                    emptyView
                } else {
                    cardsGrid
                }
            }
        }
        .navigationTitle(setName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.06, green: 0.08, blue: 0.14), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .task {
            guard !hasLoaded else { return }
            await loadSetCards()
        }
    }
    
    // MARK: - Set Header
    
    private var setHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Set icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(Theme.Font.display(32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("SET COLLECTION")
                    .font(Theme.Font.tiny(.bold))
                    .tracking(3)
                    .foregroundColor(.gray)
                
                Text(setName)
                    .font(Theme.Font.title3(.bold, .serif))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .multilineTextAlignment(.center)
                
                if !setCards.isEmpty {
                    Text("\(setCards.count) cards")
                        .font(Theme.Font.callout(.medium))
                        .foregroundColor(.purple.opacity(0.8))
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Cards Grid
    
    private var cardsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md),
                GridItem(.flexible(), spacing: Theme.Spacing.md)
            ], spacing: Theme.Spacing.md) {
                ForEach(setCards) { card in
                    NavigationLink(destination: LorcanaCardDetailView(card: card)) {
                        cardGridItem(card: card)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
        }
    }
    
    private func cardGridItem(card: LorcanaCard) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Card image
            AsyncImage(url: URL(string: card.image ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    cardPlaceholder(card: card)
                case .empty:
                    cardPlaceholder(card: card)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.7)
                        )
                @unknown default:
                    cardPlaceholder(card: card)
                }
            }
            .aspectRatio(0.714, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            .shadow(color: inkColorForCard(card).opacity(0.3), radius: 6, y: 3)
            
            // Card name
            Text(card.name)
                .font(Theme.Font.caption(.medium))
                .foregroundColor(Theme.Palette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .padding(Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Palette.surfaceUltraSubtle)
        )
    }
    
    private func cardPlaceholder(card: LorcanaCard) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.sm)
            .fill(
                LinearGradient(
                    colors: [inkColorForCard(card), inkColorForCard(card).opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "photo")
                    .font(Theme.Font.display(20))
                    .foregroundColor(Theme.Palette.textDisabled)
            )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .tint(.purple)
                .scaleEffect(1.2)
            
            Text("Loading set cards...")
                .font(Theme.Font.callout(.medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(error: LorcanaError) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Theme.Font.display(40))
                .foregroundColor(.orange)
            
            Text("Failed to load cards")
                .font(Theme.Font.subhead(.semibold))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text(error.message)
                .font(Theme.Font.body())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.huge)
            
            Button {
                Task { await loadSetCards() }
            } label: {
                Text("Retry")
                    .font(Theme.Font.callout(.semibold))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "rectangle.stack.badge.minus")
                .font(Theme.Font.display(40))
                .foregroundColor(.gray)
            
            Text("No cards found")
                .font(Theme.Font.subhead(.semibold))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text("This set doesn't have any cards yet")
                .font(Theme.Font.body())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Load Data
    
    private func loadSetCards() async {
        isLoading = true
        error = nil
        
        do {
            setCards = try await networkService.fetchCardsFromSet(setName: setName, page: 1, pageSize: 100)
            isLoading = false
            hasLoaded = true
        } catch {
            self.error = LorcanaError(message: error.localizedDescription)
            isLoading = false
            hasLoaded = true
        }
    }
    
    // MARK: - Helpers
    
    private func inkColorForCard(_ card: LorcanaCard) -> Color {
        switch card.inkColor {
        case .amber: return Color(red: 1.0, green: 0.75, blue: 0.2)
        case .amethyst: return Color(red: 0.6, green: 0.3, blue: 0.9)
        case .emerald: return Color(red: 0.2, green: 0.75, blue: 0.4)
        case .ruby: return Color(red: 0.9, green: 0.2, blue: 0.3)
        case .sapphire: return Color(red: 0.2, green: 0.5, blue: 0.9)
        case .steel: return Color(red: 0.6, green: 0.6, blue: 0.65)
        case .unknown: return Color.gray
        }
    }
}

#Preview {
    NavigationStack {
        LorcanaSetDetailView(setName: "The First Chapter")
    }
}
