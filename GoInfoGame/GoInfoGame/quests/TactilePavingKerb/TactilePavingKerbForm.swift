//
//  TactilePavingKerbForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/02/24.
//

import SwiftUI

struct TactilePavingKerbForm: View, QuestForm {
    var action: ((Bool) -> Void)?
    
    func applyAnswer(answer: Bool) {
    }
    typealias AnswerClass = Bool
    @State private var selectedAnswer:Bool = false
    @State private var showAlert = false
    @State private var showOtherAlert = false
    var body: some View {
        ZStack{
            VStack{
                QuestionHeader(icon:Image("kerb_tactile_paving"), title: LocalizedStrings.questTactilePavingKerbTitle.localized, subtitle: "Lowered Curb")
                VStack(alignment:.leading){
                    Text(LocalizedStrings.usuallyLooksLikeThis.localized).font(.caption).foregroundColor(.gray)
                    Image("tactile_paving_illustration")
                        .resizable()
                        .scaledToFill()
                    Divider()
                    YesNoView(actionBtnLabel: LocalizedStrings.cantSay.localized, action: { answer in
                        if answer == .yes || answer == .no {
                            self.showAlert.toggle()
                        } else if answer == .other{
                            self.showOtherAlert.toggle()
                        }
                    })
                } .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            /// if user selects yes/no option
            if showAlert {
                /// display are you sure alert
                CustomSureAlert(alertTitle: LocalizedStrings.questSourceDialogTitle.localized, content: LocalizedStrings.questSourceDialogNote.localized,leftBtnLabel: LocalizedStrings.undoConfirmNegative.localized, rightBtnLabel:LocalizedStrings.questGenericConfirmationYes.localized, isDontShowCheckVisible: true, onCancel: {
                    self.showAlert = false
                }, onConfirm: {
                    self.showAlert = false
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
        .allowsHitTesting(true)
    }
}

#Preview {
    TactilePavingKerbForm()
}
