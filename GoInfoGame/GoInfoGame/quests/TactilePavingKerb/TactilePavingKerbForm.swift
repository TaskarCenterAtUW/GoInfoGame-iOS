//
//  TactilePavingKerbForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/02/24.
//

import SwiftUI

struct TactilePavingKerbForm: View, QuestForm {
    func applyAnswer(answer: Bool) {
    }
    typealias AnswerClass = Bool
    @State private var selectedAnswer:Bool = false
    @State private var showAlert = false
    @State private var alertContentText: String = ""
    @State private var alertTitleText: String = ""
    @State private var leftAlertText: String = ""
    @State private var rightAlertText: String = ""
    var body: some View {
        ZStack{
            VStack{
                QuestionHeader(icon:Image("kerb_tactile_paving"), title: LocalizedStrings.questStepCountTitle.localized, subtitle: "Lowered Curb")
                VStack(alignment:.leading){
                    Text(LocalizedStrings.usuallyLooksLikeThis.localized).font(.caption).foregroundColor(.gray)
                    Image("tactile_paving_illustration")
                        .resizable()
                        .scaledToFill()
                    Divider()
                    YesNoView(actionButton3Label: LocalizedStrings.cantSay.localized){ yesNoAnswer in
                        showAlert = true
                        switch yesNoAnswer {
                        case .yes, .no:
                            configureAlert(title:  LocalizedStrings.questSourceDialogTitle.localized, content: LocalizedStrings.questSourceDialogNote.localized, leftButton: LocalizedStrings.undoConfirmNegative.localized, rightButton: LocalizedStrings.questGenericConfirmationYes.localized)
                            selectedAnswer = yesNoAnswer == .yes ? getYesNoBoolValue(.yes) : getYesNoBoolValue(.no)
                        case .other:
                            configureAlert(title: LocalizedStrings.questLeaveNewNoteTitle.localized, content: LocalizedStrings.questLeaveNewNoteDescription.localized, leftButton: LocalizedStrings.questLeaveNewNoteNo.localized, rightButton: LocalizedStrings.questLeaveNewNoteYes.localized)
                            selectedAnswer = getYesNoBoolValue(.no)
                        }
                    }
                } .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            if showAlert {
                CustomAlert(title: alertTitleText, content: {Text(alertContentText)}, leftActionText: leftAlertText, rightActionText: rightAlertText, leftButtonAction: {
                    showAlert = false
                    print("cancel tapped")
                }, rightButtonAction: {
                    showAlert = false
                    applyAnswer(answer: selectedAnswer)
                    print("selected answer",selectedAnswer)
                }, height: 200, width: 250)
            }
        }.onTapGesture {
            showAlert = false
        }
        .allowsHitTesting(true)

    }
    private func configureAlert(title: String, content: String, leftButton: String, rightButton: String) {
        alertTitleText = title
        alertContentText = content
        leftAlertText = leftButton
        rightAlertText = rightButton
    }
}

#Preview {
    TactilePavingKerbForm()
}
