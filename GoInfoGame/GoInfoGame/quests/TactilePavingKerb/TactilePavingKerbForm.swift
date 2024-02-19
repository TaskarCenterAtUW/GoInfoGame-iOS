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
                    YesNoView(action: { answer in
                        if answer == .yes || answer == .no {
                            self.showAlert.toggle()
                        }
                    })
                } .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            if showAlert {
                CustomSureAlert(onCancel: {
                    self.showAlert = false
                }, onConfirm: {
                    self.showAlert = false
                    self.action?(selectedAnswer)
                })
                .zIndex(1)
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
