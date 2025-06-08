//
//  LoadingOverlay.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//
import SwiftUI

struct LoadingOverlayView: View {
    var activityText: String
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        VStack {
            Spacer()
            ActivityView(activityText: activityText)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }
}
