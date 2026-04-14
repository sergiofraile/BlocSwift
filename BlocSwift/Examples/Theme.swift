//
//  Theme.swift
//  BlocSwift
//
//  Central design-token registry for the Bloc Examples project.
//
//  Usage:
//    .font(Theme.Font.callout(.semibold, .rounded))
//    .foregroundColor(Theme.Palette.textSecondary)
//    .padding(Theme.Spacing.lg)
//    .cornerRadius(Theme.Radius.xl)
//
//  Per-screen accent colours (cyan for Counter, red for F1, purple for Lorcana…)
//  intentionally live in each view file to preserve their individual identity.
//

import SwiftUI

// MARK: - Theme

enum Theme {

    // MARK: - Typography

    /// Semantic font scale. Every function internally applies the macOS ×1.25
    /// scaling so callers never need to think about platform differences.
    ///
    /// Use `Theme.Font.display(_:weight:design:)` for sizes outside the scale
    /// (large numeric displays, computed sizes, icon-only sizes, etc.).
    enum Font {

        // MARK: Fixed scale (iOS pt — macOS gets ×1.25 automatically)

        /// 9 pt — status badge labels ("ACTIVE", "CLOSED"), tiny icon annotations.
        static func micro(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 9, weight: weight, design: design) }

        /// 10 pt — timestamps, "PTS", small secondary labels.
        static func tiny(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 10, weight: weight, design: design) }

        /// 11 pt — secondary captions, descriptions, hint text.
        static func caption(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 11, weight: weight, design: design) }

        /// 12 pt — small body text, monospaced log messages, compact labels.
        static func footnote(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 12, weight: weight, design: design) }

        /// 13 pt — standard body text, minor button labels.
        static func body(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 13, weight: weight, design: design) }

        /// 14 pt — prominent body text, primary button labels, section text.
        static func callout(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 14, weight: weight, design: design) }

        /// 16 pt — subheadings, major action button labels.
        static func subhead(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 16, weight: weight, design: design) }

        /// 18 pt — section headings, large icon sizes.
        static func headline(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 18, weight: weight, design: design) }

        /// 22 pt — large labels (calculator buttons, prominent values).
        static func title3(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 22, weight: weight, design: design) }

        /// 28 pt — screen section titles.
        static func title(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 28, weight: weight, design: design) }

        /// 32 pt — hero section titles (Lorcana, SUVify header).
        static func title2(
            _ weight: SwiftUI.Font.Weight = .regular,
            _ design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: 32, weight: weight, design: design) }

        // MARK: Display / custom

        /// Arbitrary size — for values outside the semantic scale:
        /// dynamic calculator display, large counter numerals, icon-only sizes, etc.
        static func display(
            _ size: CGFloat,
            weight: SwiftUI.Font.Weight = .regular,
            design: SwiftUI.Font.Design = .default
        ) -> SwiftUI.Font { .scaled(size: size, weight: weight, design: design) }
    }

    // MARK: - Palette

    /// Shared chrome colours. Per-screen accent colours stay in their own views.
    enum Palette {

        // MARK: Text hierarchy
        static let textPrimary:    Color = .white
        static let textSecondary:  Color = .white.opacity(0.7)
        static let textTertiary:   Color = .white.opacity(0.5)
        static let textQuaternary: Color = .white.opacity(0.35)
        static let textDisabled:   Color = .white.opacity(0.2)
        static let textHint:       Color = .white.opacity(0.15)

        // MARK: Surfaces (glass morphism fill layers)
        static let surfaceUltraSubtle: Color = .white.opacity(0.03)
        static let surfaceSubtle:      Color = .white.opacity(0.05)
        static let surface:            Color = .white.opacity(0.08)
        static let surfaceMedium:      Color = .white.opacity(0.1)

        // MARK: Borders / strokes
        static let borderFaint:  Color = .white.opacity(0.06)
        static let border:       Color = .white.opacity(0.08)
        static let borderMedium: Color = .white.opacity(0.12)
        static let borderStrong: Color = .white.opacity(0.2)

        // MARK: Dividers
        static let divider: Color = .white.opacity(0.08)
    }

    // MARK: - Spacing

    /// Common padding / gap values (in points).
    enum Spacing {
        static let xxxs: CGFloat = 3
        static let xxs:  CGFloat = 4
        static let xs:   CGFloat = 6
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 20
        static let xxl:  CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 40
        static let max:  CGFloat = 48
    }

    // MARK: - Radius

    /// Common corner radii (in points).
    enum Radius {
        static let xs:   CGFloat = 4
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 10
        static let lg:   CGFloat = 12
        static let xl:   CGFloat = 14
        static let xxl:  CGFloat = 16
        static let xxxl: CGFloat = 20
        static let huge: CGFloat = 24
    }
}

// MARK: - Shared Loading Spinner

/// Animated arc spinner shared across all example screens.
/// Pass the `colors` array matching the screen's accent to preserve
/// each example's visual identity while sharing the animation logic.
struct LoadingSpinnerView: View {
    var colors: [Color] = [.accentColor]
    var size: CGFloat = 56

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke((colors.first ?? .gray).opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation - 90))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
        }
    }
}

// MARK: - Internal scaling primitive

/// Platform-adaptive `Font.system` wrapper.
/// On macOS sizes are multiplied by 1.25 so views designed with iOS point-sizes
/// remain comfortably readable on a non-Retina display context.
/// All `Theme.Font` functions route through here — view code should not call
/// this directly; use the semantic helpers instead.
extension Font {
    static func scaled(
        size: CGFloat,
        weight: Weight = .regular,
        design: Design = .default
    ) -> Font {
        #if os(macOS)
        return .system(size: size * 1.25, weight: weight, design: design)
        #else
        return .system(size: size, weight: weight, design: design)
        #endif
    }
}
