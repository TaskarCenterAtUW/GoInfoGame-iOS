//
//  QuestSyncButton.swift
//  GoInfoGame
//
//  Created by Prashamsa on 01/08/25.
//

import SwiftUI

struct QuestSyncButton: View {
    var badgeCount: Int
    var isSyncing: Bool
    var action: () -> Void

    @State private var rotationAngle: Double = 0
    @State private var isRotating: Bool = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image("sync")
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(isRotating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default , value: isRotating)
                    .onChange(of: isSyncing) { newValue in
                        if newValue {
                            rotationAngle = 360
                            isRotating = true
                        } else {
                            rotationAngle = 0
                            isRotating = false
                        }
                    }
                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .padding(5)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func startRotating() {
        rotationAngle = 0
        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    QuestSyncButton(badgeCount: 0 , isSyncing: true) {

    }
    .foregroundStyle(Color.green)
}
