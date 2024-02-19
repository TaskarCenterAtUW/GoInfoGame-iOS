//
//  HandRailForm.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import SwiftUI

struct HandRailForm: View, QuestForm {
    typealias AnswerClass = YesNoAnswer
    var action: ((YesNoAnswer) -> Void)?
    @State private var isShowingAreYouSure = false
    @State private var selectedAnswer: YesNoAnswer = .unknown
    
    var body: some View {
        ZStack {
            VStack{
                QuestionHeader(icon: Image("steps_handrail"),
                               title: "Do these steps have handrail?",
                               subtitle: "")
                YesNoView(action: { answer in
                    self.selectedAnswer = answer
                    if answer == .yes || answer == .no {
                        self.isShowingAreYouSure.toggle()
                    }
                })
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            if isShowingAreYouSure {
                CustomSureAlert(onCancel: {
                    self.isShowingAreYouSure = false
                }, onConfirm: {
                    self.isShowingAreYouSure = false
                    self.action?(selectedAnswer)
                    print("Answer is: \(selectedAnswer)")
                })
                .zIndex(1)
            }
        }
    }
}

#Preview {
    HandRailForm()
}
