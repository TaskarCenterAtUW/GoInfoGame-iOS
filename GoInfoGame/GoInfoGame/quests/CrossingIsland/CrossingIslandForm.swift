//
//  CrossingIslandForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 20/02/24.
//

import SwiftUI

import SwiftUI

struct CrossingIslandForm: View, QuestForm {
    var action: ((YesNoAnswer) -> Void)?
        
    typealias AnswerClass = YesNoAnswer
    @State private var isShowingAreYouSure = false
    @State private var selectedAnswer: YesNoAnswer = .unknown
    @State private var showOtherAlert = false
    
    var body: some View {
        ZStack {
            VStack{
                QuestionHeader(icon: Image("ic_quest_pedestrian_crossing_island"),
                               title: LocalizedStrings.questPedestrianCrossingIsland.localized,
                               subtitle: "Unmarked Crossing")
                YesNoView(actionBtnLabel: LocalizedStrings.cantSay.localized, action: { answer in
                    self.selectedAnswer = answer
                    if answer == .yes || answer == .no {
                        self.isShowingAreYouSure.toggle()
                    } else if answer == .other {
                        self.showOtherAlert.toggle()
                    }
                })
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            if isShowingAreYouSure {
                CustomSureAlert(alertTitle: LocalizedStrings.questSourceDialogTitle.localized, content: LocalizedStrings.questSourceDialogNote.localized,leftBtnLabel: LocalizedStrings.undoConfirmNegative.localized, rightBtnLabel:LocalizedStrings.questGenericConfirmationYes.localized, isDontShowCheckVisible: true,onCancel: {
                    self.isShowingAreYouSure = false
                }, onConfirm: {
                    self.isShowingAreYouSure = false
                    self.action?(selectedAnswer)
                })
                .zIndex(1)
            }
            /// if user selects other answers option
            if showOtherAlert {
                /// display leave a note instead alert
                CustomSureAlert(alertTitle: LocalizedStrings.questLeaveNewNoteTitle.localized, content: LocalizedStrings.questLeaveNewNoteDescription.localized,leftBtnLabel: LocalizedStrings.questLeaveNewNoteNo.localized, rightBtnLabel:LocalizedStrings.questLeaveNewNoteYes.localized, isDontShowCheckVisible: false, onCancel: {
                    self.showOtherAlert = false
                }, onConfirm: {
                    self.showOtherAlert = false
                })
            }
        }
    }
}

#Preview {
    CrossingIslandForm()
}
