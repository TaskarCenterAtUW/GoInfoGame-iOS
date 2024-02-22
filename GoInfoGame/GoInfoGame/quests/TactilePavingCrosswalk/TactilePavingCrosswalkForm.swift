//
//  TactilePavingCrosswalkForm.swift
//  GoInfoGame
//
//  Created by Rajesh Kantipudi on 20/02/24.
//

import Foundation
import SwiftUI

struct TactilePavingCrosswalkForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
    typealias AnswerClass = YesNoAnswer
    @State private var isShowingAreYouSure = false
    @State private var selectedAnswer: YesNoAnswer = .unknown
    
    var body: some View {
        ZStack {
            VStack{
                QuestionHeader(icon:Image("tactile_crossing"),
                               title: LocalizedStrings.questTactilePavingCrossing.localized,
                               subtitle: "Marked Crossing")
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
                            self.isShowingAreYouSure.toggle()
                        }
                    })
                } .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            if isShowingAreYouSure {
                CustomSureAlert(onCancel: {
                    self.isShowingAreYouSure = false
                }, onConfirm: {
                    self.isShowingAreYouSure = false
                    self.action?(selectedAnswer)
                })
                .zIndex(1)
            }
        }.frame(maxHeight: .leastNormalMagnitude)
    }
}

#Preview {
    TactilePavingCrosswalkForm()
}
