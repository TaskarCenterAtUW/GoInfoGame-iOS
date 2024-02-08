//
//  TactilePavingStepsForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct TactilePavingStepsForm: View, QuestForm {
    func applyAnswer(answer: TactilePavingStepsAnswer) {
    }
    typealias AnswerClass = TactilePavingStepsAnswer
    
    var body: some View {
        VStack{
            QuestionHeader(icon:Image("steps_tactile_paving"), title: LocalizedStrings.questTactilePavingTitleSteps.localized, subtitle: "Stair Number")
            VStack(alignment:.leading){
                Text(LocalizedStrings.usuallyLooksLikeThis.localized).font(.caption).foregroundColor(.gray)
                Image("tactile_paving_illustration")
                    .resizable()
                    .scaledToFill()
                Divider()
                YesNoView(actionButton3Label: LocalizedStrings.otherAnswers.localized, onYesNoAnswerSelected: {_ in })
            } .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }.padding()
    }
}

#Preview {
    TactilePavingStepsForm()
}
