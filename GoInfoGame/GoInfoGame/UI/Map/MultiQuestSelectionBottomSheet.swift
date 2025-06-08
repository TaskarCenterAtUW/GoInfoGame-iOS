//
//  MultiQuestSelectionBottomSheet.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 08/06/25.
//

import SwiftUI

struct MultiQuestSelectionBottomSheet: View {
    var selectedAnnotationType: String
    var selectedAnnotationImage: UIImage
    var selectedCount: Int
    var onCancel: () -> Void
    var onAnswerQuests: () -> Void

    var body: some View {
        VStack() {
            HStack {
                Image(uiImage: selectedAnnotationImage)
                    .resizable()
                    .frame(width: 20.0, height: 20.0)
                    .foregroundColor(.gray)
                Text("**Select \(selectedAnnotationType):**")
                    .font(.headline)
                Text("\(selectedCount) \(selectedAnnotationType.lowercased()) selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding()
            VStack() {
                Button(action: onAnswerQuests) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right")
                        Text("Answer Quests")
                        Spacer()
                    }
                }
                .padding()

                Divider()

                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel")
                        Spacer()
                    }
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(20.0)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
        .frame(maxHeight: .infinity, alignment: .bottom) // Ensures it stays at the bottom
    }
}
