//
//  QuestAnswerView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct QuestAndDescriptionView: View {
    var quest: Ques
    var answerView: some View {
            switch quest.answerType {
            case .WIDTH:
                AddSideWalksWidthView(selectedQuest: quest) { feet, inches, isConfirmAlert in
                            print("Feet: \(feet), Inches: \(inches), isConfirmAlert: \(isConfirmAlert)")
                        }
            }
        }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(quest.icon)
                    .foregroundColor(.blue)
                    .frame(alignment: Alignment.center).padding(.top,20)
                Spacer()
            }
            Text(quest.title)
                .font(.headline)
            Text(quest.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top,2)
            answerView
            Spacer()
        }.padding(20)
    }
}
