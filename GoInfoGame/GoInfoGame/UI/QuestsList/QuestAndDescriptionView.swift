//
//  QuestAnswerView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

protocol AnswerView: View {
    var selectedQuest: Ques { get }
}
struct QuestAndDescriptionView: View {
    var quest: Ques
    @ViewBuilder
    var answerView:  some View {
            switch quest.answerType {
            case .WIDTH:
                    AddSideWalksWidthView(selectedQuest: quest) { feet, inches, isConfirmAlert in
                        print("Feet: \(feet), Inches: \(inches), isConfirmAlert: \(isConfirmAlert)")
                    }
            case .YESNO:
                    AddHandrailView(selectedQuest: quest)
            }
        }
    var body: some  View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(quest.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .frame(alignment: Alignment.center).padding(.top,20)
                Spacer()
            }
            Text(quest.title)
                .font(.headline)
                .padding(.top,10)
            Text(quest.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top,2)
            answerView
            Spacer()
        }.padding(20)
    }
}
