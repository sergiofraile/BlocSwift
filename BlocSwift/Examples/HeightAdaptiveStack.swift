//
//  HeightAdaptiveStack.swift
//  BlocSwift
//

import SwiftUI

/// Portrait container for screens that may be short — iPhone Duo's cover display
/// (~580pt usable under the navigation bar), iPhone SE, Stage Manager windows.
///
/// - Passes `dense: true` to `content` when the available height is below
///   `denseBelow`, so the example can tighten spacing and shrink hero elements.
/// - Fills the full height, so `Spacer`s still distribute on tall screens.
/// - Scrolls instead of clipping when even the dense layout doesn't fit.
struct HeightAdaptiveStack<Content: View>: View {
    var denseBelow: CGFloat = 640
    @ViewBuilder let content: (_ dense: Bool) -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content(geo.size.height < denseBelow)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
