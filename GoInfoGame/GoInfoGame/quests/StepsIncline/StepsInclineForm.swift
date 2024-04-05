//
//  StepsInclineForm.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import SwiftUI

struct StepsInclineForm: View, QuestForm {
    var action: ((StepsInclineDirection) -> Void)?
    typealias AnswerClass = StepsInclineDirection
    @State private var selectedImage : [String] = []
    @State private var showAlert = false
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var contextualInfo: ContextualInfo
    
    let imageData: [ImageData] = [
        ImageData(id:"UP",type: "none", imageName: "steps-incline-up", tag: "up", optionName: LocalizedStrings.questStepsInclineUp.localized),
        ImageData(id:"UP_REVERSED",type: "bicycle", imageName: "steps-incline-up-reversed", tag: "down", optionName: LocalizedStrings.questStepsInclineUp.localized),
    ]
    var body: some View {
        VStack{
            DismissButtonView {
                withAnimation {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            QuestionHeader(icon: Image("steps"), title: "Which direction leads upwards for the steps", contextualInfo: contextualInfo.info)
            VStack (alignment: .leading){
                Text(LocalizedStrings.selectOne.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 2, isLabelBelow: true, imageData: imageData, isImageRotated: true, isDisplayImageOnly: false, isScrollable: false, allowMultipleSelection: false, onTap: { (selectedImage) in
                    action?(.down)
                }, selectedImages:$selectedImage)
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
