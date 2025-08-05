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

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image("upload_sync")

                if isSyncing {
                    rotatingSyncIcon
                        .offset(x: 5, y: -5)
                        .onAppear {
                            startRotating()
                        }
                        .onDisappear {
                            rotationAngle = 0
                        }
                } else if badgeCount > 0 {
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
        .onChange(of: isSyncing) { newValue in
            if newValue {
                startRotating()
            } else {
                rotationAngle = 0
            }
        }
    }

    var rotatingSyncIcon: some View {
        Image("sync")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundStyle(.red)
            .rotationEffect(.degrees(rotationAngle), anchor: .center)
    }

    private func startRotating() {
        rotationAngle = 0
        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

#Preview {
    QuestSyncButton(badgeCount: 01, isSyncing: true) {

    }
    .foregroundStyle(Color.green)
}
