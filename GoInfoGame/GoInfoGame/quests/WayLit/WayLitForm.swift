//
//  WayLitForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct WayLitForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
    typealias AnswerClass = YesNoAnswer
    @State private var isShowingAreYouSure = false
    @State private var selectedAnswer: YesNoAnswer = .unknown

    
    var body: some View {
        ZStack {
            VStack{
                QuestionHeader(icon: Image("add_way_lit"),
                               title: LocalizedStrings.questLitTitle.localized,
                               subtitle: "SideWalk")
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
    WayLitForm()
}
