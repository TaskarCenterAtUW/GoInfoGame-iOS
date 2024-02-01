//
//  SideWalkValidationForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 31/01/24.
//

import SwiftUI

struct SideWalkValidationForm: QuestForm ,View {
    func applyAnswer(answer: SideWalkValidationAnswer) {
    }
    
    @State private var showAlert = false
    typealias AnswerClass = SideWalkValidationAnswer
    
    var body: some View {
        VStack (alignment: .leading){
            QuestionHeader(icon: Image("sidewalk"), title: LocalizedStrings.questSidewalkTitle.localized, subtitle: "Street").padding(.bottom,10)
            VStack(alignment: .leading){
                Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 2, isLabelBelow: true, imageData: SideWalksImageData, isImageRotated: false, isDisplayImageOnly: false, onTap: { (type, tag) in
                    print("Clicked: \(type), Tag: \(tag)")})
                Divider()
                HStack() {
                    Spacer()
                    Button {
                        showAlert = true
                    } label: {
                        Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("More Questions"))
                    }.frame(alignment: .center)
                    Spacer()
                }.padding(.top,10)
            }        .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }
        .padding()
    }
    }


#Preview {
    SideWalkValidationForm()
}
