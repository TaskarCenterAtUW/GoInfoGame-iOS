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
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack{
            VStack{
                DismissButtonView {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding([.top], 30)
                QuestionHeader(icon:Image("kerb_tactile_paving"), title: LocalizedStrings.questTactilePavingKerbTitle.localized, contextualInfo: "Lowered Curb")
                VStack(alignment:.leading){
                    Text(LocalizedStrings.usuallyLooksLikeThis.localized).font(.caption).foregroundColor(.gray)
                    Image("tactile_paving_illustration")
                        .resizable()
                        .scaledToFill()
                    Divider()
                    YesNoView(actionBtnLabel: LocalizedStrings.cantSay.localized, action: { answer in
                        if answer == .yes || answer == .no {
                            self.action?(selectedAnswer)
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
