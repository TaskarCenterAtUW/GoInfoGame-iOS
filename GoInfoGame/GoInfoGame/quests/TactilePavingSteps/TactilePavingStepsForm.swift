//
//  TactilePavingStepsForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct TactilePavingStepsForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
    typealias AnswerClass = YesNoAnswer
    @State private var isShowingAreYouSure = false
    @State private var selectedAnswer: YesNoAnswer = .unknown
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            VStack{
                DismissButtonView {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                QuestionHeader(icon:Image("steps_tactile_paving"),
                               title: LocalizedStrings.questTactilePavingTitleSteps.localized,
                               contextualInfo: "Stair Number")
                VStack(alignment:.leading){
                    Text(LocalizedStrings.usuallyLooksLikeThis.localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Image("tactile_paving_illustration")
                        .resizable()
                        .scaledToFill()
                    Divider()
                    YesNoView(actionBtnLabel: LocalizedStrings.otherAnswers.localized, action: { answer in
                        self.selectedAnswer = answer
                        if answer == .yes || answer == .no {
                            self.action?(selectedAnswer)
                        }
                    })
                } .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
        }
    }
}

#Preview {
    TactilePavingStepsForm()
}
