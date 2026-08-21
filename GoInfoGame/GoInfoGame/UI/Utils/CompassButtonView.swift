//
//  CompassButtonView.swift
//  GoInfoGame
//

import SwiftUI

/// Custom compass control — replaces MapLibre's built-in `MLNCompassButton`
/// (a bare `UIImageView` with no background chip, pinned via UIKit margins)
/// with a standalone button matching the zoom/locate buttons' style: a white
/// circle with a shadow, using the app's own `compass_needle` asset. Rotates
/// to match the map's current bearing and, like the built-in compass, only
/// appears once the map is rotated off north; tapping it resets north.
struct CompassButtonView: View {
    /// Current map rotation, in degrees clockwise from north.
    let heading: Double
    let onTap: () -> Void

    private var isRotated: Bool { abs(heading) > 0.01 }

    var body: some View {
        if isRotated {
            Button(action: onTap) {
                Image("compass_needle")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                    .rotationEffect(.degrees(-heading))
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(radius: 10)
            }
            .accessibilityLabel(L10n.Localizable.resetMapOrientationToNorth)
            .accessibilitySortPriority(1)
        }
    }
}

#Preview {
    CompassButtonView(heading: 45) {}
}
