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
                AddSideWalksWidthView()
            }
        }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image(quest.icon)
                    .foregroundColor(.blue)
                    .frame(alignment: Alignment.center)
                Spacer()
            }
            Text(quest.title)
                .font(.headline)
                .padding(.top,10)
            Text(quest.subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
            answerView
            Spacer()
        }.padding(20)
    }
}
