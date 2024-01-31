//
//  StepsInclineForm.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import SwiftUI

struct StepsInclineForm: View, QuestForm {
    var action: ((StepsInclineDirection) -> Void)?
    
    func applyAnswer(answer: StepsInclineDirection) {
        // TODO
    }
    
    typealias AnswerClass = StepsInclineDirection
    @State private var selectedImage : String?
    
    @State private var showAlert = false
    let imageData: [ImageData] = [
        ImageData(id:"UP",type: "none", imageName: "steps-incline-up", tag: "up", optionName: LocalizedStrings.questStepsInclineUp.localized),
        ImageData(id:"UP_REVERSED",type: "bicycle", imageName: "steps-incline-up-reversed", tag: "down", optionName: LocalizedStrings.questStepsInclineUp.localized),
    ]
    var body: some View {
        VStack{
            
            
            QuestionHeader(icon: Image("steps"), title: "Which direction leads upwards for the steps", subtitle: "steps")
            VStack (alignment: .leading){
                Text(LocalizedStrings.selectOne.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 2, isLabelBelow: true, imageData: imageData, isImageRotated: true, isDisplayImageOnly: false, onTap: { (type, tag) in
                    print("Clicked: \(type), Tag: \(tag)")}, selectedImage:$selectedImage)
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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .gray, radius: 2, x: 0, y: 2))
        }.padding()
    }
}

#Preview {
    StepsInclineForm()
}
