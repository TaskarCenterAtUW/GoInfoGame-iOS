//
//  AddSideWalksWidthView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 09/01/24.
//

import SwiftUI

struct SideWalkWidthForm: View, QuestForm {
    
    func applyAnswer(answer: WidthAnswer) {
        
    }
    
    typealias AnswerClass = WidthAnswer
    
    @State private var showAlert = false
    @State private var feet: Double = 0.0
    @State private var inches: Double = 0.0
    @State private var isConfirmAlert: Bool = false
//    var selectedQuest: Ques
    var onConfirm: ((_ feet: Double, _ inches: Double, _ isConfirmAlert: Bool) -> Void)?
    
    func processAnswer() {
        // Generate the answer
        let answer = WidthAnswer(width: "33", units: "aa", isARMeasurement: false)
        applyAnswer(answer:answer)
    }
    var body: some View {
        VStack{
            QuestionHeader(icon: Image("add_way_lit"), title: "How wide is the road here?", subtitle: "Residential Road")
            Text("").font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray)
                .padding(.top,10)
            WidthView(feet: $feet, inches: $inches, isConfirmAlert: $isConfirmAlert)
            Divider()
            Button {
                showAlert = true
            } label: {
                Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("More Questions"))
            }
            .padding(.top,10)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(isPresented: $isConfirmAlert) {
            Alert(
                title: Text(LocalizedStrings.questGenericConfirmationTitle.localized),
                message: Text(LocalizedStrings.questRoadWidthUnusualInputConfirmation.localized),
                primaryButton: .default(Text(LocalizedStrings.questGenericConfirmationYes.localized)) {
                    print("OK button tapped")
                    onConfirm?(feet, inches, isConfirmAlert)
                },
                secondaryButton: .default(Text(LocalizedStrings.questGenericConfirmationNo.localized))
            )
        }
    }
}

#Preview {
    SideWalkWidthForm()
}
