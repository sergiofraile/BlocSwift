//
//  LorcanaCardDetailView.swift
//  BlocSwift
//
//  Created by Cursor on 19/01/2026.
//

import SwiftUI

struct LorcanaCardDetailView: View {
    
    let card: LorcanaCard

    /// Controls whether the full-screen card zoom overlay is shown.
    @State private var isCardExpanded = false

    var body: some View {
        ZStack {
            // Background gradient matching ink colour
            LinearGradient(
                colors: [
                    inkColorForCard(card).opacity(0.15),
                    Color(red: 0.06, green: 0.04, blue: 0.12),
                    Color(red: 0.08, green: 0.06, blue: 0.14)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.xxl) {
                    cardImageSection
                    headerSection
                    
                    if hasStats { statsSection }
                    
                    detailsSection
                    
                    if let setName = card.setName {
                        setSection(setName: setName)
                    }
                    
                    if let flavorText = card.flavorText, !flavorText.isEmpty {
                        flavorTextSection(flavorText: flavorText)
                    }
                    
                    if let bodyText = card.bodyText, !bodyText.isEmpty {
                        bodyTextSection(bodyText: bodyText)
                    }
                    
                    Spacer(minLength: Theme.Spacing.huge)
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.xl)
            }

            // Full-screen card zoom overlay — sits above everything in the ZStack
            if isCardExpanded {
                expandedCardOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(inkColorForCard(card).opacity(0.3), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isCardExpanded)
    }
    
    // MARK: - Card Image

    private var cardImageSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            cardImage(maxWidth: 280)
                // Subtle press-in scale so the tap feels responsive
                .scaleEffect(isCardExpanded ? 0.94 : 1.0)
                .onTapGesture {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        isCardExpanded = true
                    }
                }

            // Tap hint
            Label("Tap to enlarge", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(Theme.Font.caption())
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    /// Renders the card image (or placeholder) at the given max width.
    private func cardImage(maxWidth: CGFloat) -> some View {
        AsyncImage(url: URL(string: card.image ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.xxl))
                    .shadow(color: inkColorForCard(card).opacity(0.5), radius: 20, y: 10)
            case .failure:
                cardPlaceholder
            case .empty:
                cardPlaceholder
                    .overlay(ProgressView().tint(.white))
            @unknown default:
                cardPlaceholder
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Expanded overlay

    /// Full-screen overlay that shows the card at maximum readable size.
    ///
    /// Tapping anywhere — backdrop or card — springs the card back to its
    /// original position.
    private var expandedCardOverlay: some View {
        ZStack {
            // Blurred, darkened backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color.black.opacity(0.75))
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: Theme.Spacing.xl) {
                // Enlarged card — springs in from small to full size
                cardImage(maxWidth: .infinity)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .transition(
                        .scale(scale: 0.55, anchor: .top)
                        .combined(with: .opacity)
                    )
                    .onTapGesture { dismiss() }

                // Dismiss hint
                Label("Tap anywhere to close", systemImage: "xmark.circle")
                    .font(Theme.Font.caption())
                    .foregroundStyle(.white.opacity(0.45))
                    .transition(.opacity)
            }
        }
    }

    private func dismiss() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            isCardExpanded = false
        }
    }
    
    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.xxl)
            .fill(
                LinearGradient(
                    colors: [inkColorForCard(card), inkColorForCard(card).opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .aspectRatio(0.714, contentMode: .fit)
            .overlay(
                Image(systemName: "photo")
                    .font(Theme.Font.display(40))
                    .foregroundColor(Theme.Palette.textTertiary)
            )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text(card.name)
                .font(Theme.Font.title(.bold, .serif))
                .foregroundColor(Theme.Palette.textPrimary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: Theme.Spacing.md) {
                if let type = card.type {
                    Text(type.uppercased())
                        .font(Theme.Font.footnote(.bold))
                        .tracking(2)
                        .foregroundColor(inkColorForCard(card))
                }
                
                if let classifications = card.classifications, !classifications.isEmpty {
                    Text("•")
                        .foregroundColor(.gray)
                    Text(classifications)
                        .font(Theme.Font.footnote(.medium))
                        .foregroundColor(.gray)
                }
            }
            
            if let rarity = card.rarity {
                rarityBadge(rarity: rarity)
            }
        }
    }
    
    private func rarityBadge(rarity: String) -> some View {
        Text(rarity)
            .font(Theme.Font.caption(.bold))
            .foregroundColor(Theme.Palette.textPrimary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule()
                    .fill(rarityColor(rarity))
            )
    }
    
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common": return .gray
        case "uncommon": return .green
        case "rare": return .blue
        case "super rare": return .purple
        case "legendary": return .orange
        case "enchanted": return Color(red: 1.0, green: 0.8, blue: 0.3)
        default: return .gray
        }
    }
    
    // MARK: - Stats
    
    private var hasStats: Bool {
        card.cost != nil || card.strength != nil || card.willpower != nil || card.lore != nil
    }
    
    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            if let cost = card.cost {
                statCard(title: "INK COST", value: "\(cost)", icon: "drop.fill", color: inkColorForCard(card))
            }
            if let strength = card.strength {
                statCard(title: "STRENGTH", value: "\(strength)", icon: "bolt.fill", color: .orange)
            }
            if let willpower = card.willpower {
                statCard(title: "WILLPOWER", value: "\(willpower)", icon: "shield.fill", color: .blue)
            }
            if let lore = card.lore {
                statCard(title: "LORE", value: "\(lore)", icon: "star.fill", color: .yellow)
            }
        }
        .padding(.horizontal, Theme.Spacing.xxs)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(Theme.Font.display(20))
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Font.display(24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Palette.textPrimary)
            
            Text(title)
                .font(Theme.Font.micro(.bold))
                .tracking(1)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .fill(Theme.Palette.surfaceSubtle)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.lg)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Details
    
    private var detailsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            if let color = card.color {
                detailRow(label: "Ink Color", value: color, icon: "paintpalette.fill")
            }
            
            if card.inkable == true {
                detailRow(label: "Inkable", value: "Yes", icon: "checkmark.circle.fill")
            } else if card.inkable == false {
                detailRow(label: "Inkable", value: "No", icon: "xmark.circle.fill")
            }
            
            if let artist = card.artist {
                detailRow(label: "Artist", value: artist, icon: "paintbrush.fill")
            }
            
            if let franchises = card.franchises, !franchises.isEmpty {
                detailRow(label: "Franchise", value: franchises, icon: "film.fill")
            }
            
            if let cardNum = card.cardNum, let setNum = card.setNum {
                detailRow(label: "Card Number", value: "\(cardNum) / \(setNum)", icon: "number")
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                .fill(Theme.Palette.surfaceSubtle)
        )
    }
    
    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(Theme.Font.callout())
                .foregroundColor(inkColorForCard(card))
                .frame(width: 24)
            
            Text(label)
                .font(Theme.Font.callout(.medium))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(Theme.Font.callout(.semibold))
                .foregroundColor(Theme.Palette.textPrimary)
        }
    }
    
    // MARK: - Set Section
    
    private func setSection(setName: String) -> some View {
        NavigationLink(destination: LorcanaSetDetailView(setName: setName)) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("SET")
                        .font(Theme.Font.tiny(.bold))
                        .tracking(2)
                        .foregroundColor(.gray)
                    
                    Text(setName)
                        .font(Theme.Font.subhead(.semibold))
                        .foregroundColor(Theme.Palette.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(Theme.Font.callout(.semibold))
                    .foregroundColor(inkColorForCard(card))
            }
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                    .fill(
                        LinearGradient(
                            colors: [inkColorForCard(card).opacity(0.15), Theme.Palette.surfaceSubtle],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                            .stroke(inkColorForCard(card).opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Flavor Text
    
    private func flavorTextSection(flavorText: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("FLAVOR TEXT")
                .font(Theme.Font.tiny(.bold))
                .tracking(2)
                .foregroundColor(.gray)
            
            Text(flavorText)
                .font(Theme.Font.callout(.regular, .serif))
                .italic()
                .foregroundColor(Color(red: 0.8, green: 0.75, blue: 0.9))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                .fill(Theme.Palette.surfaceUltraSubtle)
        )
    }
    
    // MARK: - Body Text
    
    private func bodyTextSection(bodyText: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("ABILITIES")
                .font(Theme.Font.tiny(.bold))
                .tracking(2)
                .foregroundColor(.gray)
            
            Text(bodyText)
                .font(Theme.Font.callout())
                .foregroundColor(Theme.Palette.textPrimary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.xxl)
                .fill(Theme.Palette.surfaceSubtle)
        )
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
        LorcanaCardDetailView(card: LorcanaCard(
            name: "Mickey Mouse - True Friend",
            artist: "Disney Artist",
            setName: "The First Chapter",
            setNum: 204,
            color: "Amber",
            image: nil,
            cost: 3,
            inkable: true,
            type: "Character",
            classifications: "Storyborn, Hero",
            abilities: "Rush",
            flavorText: "A true friend is always there when you need them.",
            franchises: "Mickey & Friends",
            rarity: "Legendary",
            strength: 3,
            willpower: 4,
            lore: 2,
            cardNum: 1,
            bodyText: "When this character enters play, draw a card.",
            setId: "TFC"
        ))
    }
}
