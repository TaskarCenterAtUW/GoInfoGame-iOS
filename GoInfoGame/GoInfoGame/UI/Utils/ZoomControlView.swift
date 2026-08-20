//
//  ZoomControlView.swift
//  GoInfoGame
//

import SwiftUI

/// Grouped zoom in/out control — a single capsule containing both icons with
/// a thin divider between them, matching the stacked-pill layout used by
/// system map apps, instead of two separate circular buttons.
struct ZoomControlView: View {
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onZoomIn) {
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.Localizable.zoomInMap)
            .accessibilitySortPriority(1)

            Rectangle()
                .fill(Asset.Colors.ddddddLine.swiftUIColor)
                .frame(width: 30, height: 1)

            Button(action: onZoomOut) {
                Image(systemName: "minus")
                    .font(.system(size: 18))
                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(L10n.Localizable.zoomOutMap)
            .accessibilitySortPriority(1)
        }
        .background(.white)
        .clipShape(Capsule())
        .shadow(radius: 10)
    }
}

#Preview {
    ZoomControlView(onZoomIn: {}, onZoomOut: {})
}
