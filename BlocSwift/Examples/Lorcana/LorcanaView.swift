//
//  LorcanaView.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import Bloc
import SwiftUI

struct LorcanaView: View {
    
    let lorcanaBloc = BlocRegistry.resolve(LorcanaBloc.self)
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Magical gradient background — Lorcana accent: purple/amethyst
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.06, blue: 0.14),
                        Color(red: 0.12, green: 0.08, blue: 0.20),
                        Color(red: 0.06, green: 0.04, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Starfield effect
                GeometryReader { geometry in
                    ForEach(0..<30, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.1...0.4)))
                            .frame(width: CGFloat.random(in: 1...3))
                            .position(
                                x: CGFloat.random(in: 0...geometry.size.width),
                                y: CGFloat.random(in: 0...geometry.size.height)
                            )
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBarSection
                    contentView
                }
            }
            .navigationTitle("Lorcana Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.08, green: 0.06, blue: 0.14), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .tint(.white)
    }
    
    // MARK: - Search Bar
    
    private var searchBarSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(Theme.Font.subhead())
                
                TextField("Search cards...", text: $searchText)
                    .foregroundColor(Theme.Palette.textPrimary)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            lorcanaBloc.send(.clear)
                        } else {
                            // Debounce is handled by the .debounce transformer
                            // registered in LorcanaBloc — no manual task needed.
                            lorcanaBloc.send(.search(query: newValue))
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        lorcanaBloc.send(.clear)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .fill(Theme.Palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(Theme.Palette.borderMedium, lineWidth: 1)
                    )
            )
            
            // Fetch All button
            Button {
                searchText = ""
                lorcanaBloc.send(.fetchAllCards)
            } label: {
                Image(systemName: "sparkles")
                    .font(Theme.Font.headline(.semibold))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.9),
                                Color(red: 0.4, green: 0.2, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .shadow(color: .purple.opacity(0.4), radius: 8, y: 4)
            }
        }
        .frame(maxWidth: 600)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        let state = lorcanaBloc.state
        
        if state.isLoading && state.cards.isEmpty {
            loadingView
        } else if let error = state.error, state.cards.isEmpty {
            errorView(error: error)
        } else if state.cards.isEmpty && !state.isSearching {
            initialStateView
        } else if state.cards.isEmpty && state.isSearching {
            noResultsView
        } else {
            cardsListView
        }
    }
    
    // MARK: - Initial State
    
    private var initialStateView: some View {
        VStack(spacing: 28) {
            // Magic portal icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.9).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.6, green: 0.3, blue: 0.9),
                                Color(red: 0.4, green: 0.2, blue: 0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .purple.opacity(0.5), radius: 20, y: 8)
                
                Image(systemName: "wand.and.stars")
                    .font(Theme.Font.display(40, weight: .medium))
                    .foregroundColor(Theme.Palette.textPrimary)
            }
            
            VStack(spacing: Theme.Spacing.md) {
                Text("DISNEY")
                    .font(Theme.Font.footnote(.bold))
                    .tracking(6)
                    .foregroundColor(.gray)
                
                Text("Lorcana")
                    .font(Theme.Font.title2(.bold, .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.8, green: 0.7, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Card Collection")
                    .font(Theme.Font.subhead(.medium))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("Search for cards or tap the sparkle")
                    .font(Theme.Font.callout())
                    .foregroundColor(.gray)
                Text("button to browse all cards")
                    .font(Theme.Font.callout())
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            LoadingSpinnerView(colors: [.purple, .pink])

            Text("Summoning cards...")
                .font(Theme.Font.subhead(.medium, .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Cards List
    
    private var cardsListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                ForEach(lorcanaBloc.state.cards) { card in
                    NavigationLink(destination: LorcanaCardDetailView(card: card)) {
                        cardRow(card: card)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if card == lorcanaBloc.state.cards.last {
                            lorcanaBloc.send(.loadNextPage)
                        }
                    }
                }
                
                // BlocSelector: only rebuilds this footer when isLoadingMore
                // changes — the card list scrolls without triggering this view.
                BlocSelector(LorcanaBloc.self, selector: \.isLoadingMore) { isLoadingMore in
                    if isLoadingMore {
                        HStack(spacing: Theme.Spacing.md) {
                            ProgressView()
                                .tint(.purple)
                            Text("Loading more...")
                                .font(Theme.Font.callout())
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, Theme.Spacing.xl)
                    }
                }

                // BlocSelector: only rebuilds when the pagination summary changes
                // (hasMorePages or card count), not on every individual card append.
                BlocSelector(
                    LorcanaBloc.self,
                    selector: { PaginationSummary(hasMore: $0.hasMorePages, count: $0.cards.count) }
                ) { summary in
                    if !summary.hasMore && summary.count > 0 {
                        Text("You've seen all \(summary.count) cards!")
                            .font(Theme.Font.callout())
                            .foregroundColor(.gray)
                            .padding(.vertical, Theme.Spacing.xl)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
        }
    }
    
    // MARK: - Card Row
    
    private func cardRow(card: LorcanaCard) -> some View {
        HStack(spacing: 14) {
            // Card image thumbnail
            AsyncImage(url: URL(string: card.image ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    inkColorPlaceholder(card: card)
                case .empty:
                    inkColorPlaceholder(card: card)
                        .overlay(ProgressView().tint(.white))
                @unknown default:
                    inkColorPlaceholder(card: card)
                }
            }
            .frame(width: 60, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xs))
            
            // Card info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(card.name)
                    .font(Theme.Font.subhead(.semibold))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: Theme.Spacing.sm) {
                    if let cost = card.cost {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "drop.fill")
                                .font(Theme.Font.tiny())
                            Text("\(cost)")
                                .font(Theme.Font.footnote(.bold))
                        }
                        .foregroundColor(inkColorForCard(card))
                    }
                    
                    if let type = card.type {
                        Text(type)
                            .font(Theme.Font.footnote())
                            .foregroundColor(.gray)
                    }
                    
                    if let rarity = card.rarity {
                        Text("• \(rarity)")
                            .font(Theme.Font.footnote())
                            .foregroundColor(.gray)
                    }
                }
                
                if let setName = card.setName {
                    Text(setName)
                        .font(Theme.Font.caption(.medium))
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Stats column
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                if let strength = card.strength {
                    statBadge(icon: "bolt.fill", value: strength, color: .orange)
                }
                if let willpower = card.willpower {
                    statBadge(icon: "shield.fill", value: willpower, color: .blue)
                }
                if let lore = card.lore {
                    statBadge(icon: "star.fill", value: lore, color: .yellow)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(Theme.Font.callout(.semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xl)
                .fill(Theme.Palette.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [inkColorForCard(card).opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func inkColorPlaceholder(card: LorcanaCard) -> some View {
        RoundedRectangle(cornerRadius: Theme.Radius.xs)
            .fill(
                LinearGradient(
                    colors: [inkColorForCard(card), inkColorForCard(card).opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private func statBadge(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xxxs) {
            Image(systemName: icon)
                .font(Theme.Font.micro())
            Text("\(value)")
                .font(Theme.Font.caption(.bold))
        }
        .foregroundColor(color)
    }
    
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
    
    // MARK: - Error View
    
    private func errorView(error: LorcanaError) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Theme.Font.display(44))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(Theme.Font.headline(.semibold))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text(error.message)
                .font(Theme.Font.callout())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.huge)
            
            Button {
                lorcanaBloc.send(.fetchAllCards)
            } label: {
                Text("Try Again")
                    .font(Theme.Font.callout(.semibold))
                    .foregroundColor(Theme.Palette.textPrimary)
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Color.purple)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Results View
    
    private var noResultsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(Theme.Font.display(40))
                .foregroundColor(.gray)
            
            Text("No cards found")
                .font(Theme.Font.headline(.semibold))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text("Try a different search term")
                .font(Theme.Font.callout())
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
}

// MARK: - BlocSelector value types

/// Equatable snapshot used by the pagination `BlocSelector`.
///
/// Bundling both fields in one struct lets a single selector track the full
/// "is there more to load?" story — and `BlocSelector` only rebuilds the
/// footer when *either* value changes.
private struct PaginationSummary: Equatable {
    let hasMore: Bool
    let count: Int
}

#Preview {
    NavigationStack {
        LorcanaView()
    }
}
