//
//  StepsRampForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import SwiftUI

struct StepsRampForm: View, QuestForm {
    var action: ((StepsRampAnswer) -> Void)?
    
    func applyAnswer(answer: StepsRampAnswer) {
    }
    typealias AnswerClass = StepsRampAnswer
    @State private var selectedImage:String?
    @State private var showAlert = false
    let imageData: [ImageData] = [
        ImageData(id:"ramp_none",type: "none", imageName: "ramp_none", tag: "none", optionName: LocalizedStrings.questStepsRampNone.localized),
        ImageData(id:"ramp_bicycle",type: "bicycle", imageName: "ramp_bicycle", tag: "ramp:wheelchair", optionName: LocalizedStrings.questStepsRampBicycle.localized),
        ImageData(id:"ramp_stroller",type: "stroller", imageName: "ramp_stroller", tag: "ramp:stroller", optionName: LocalizedStrings.questStepsRampStroller.localized),
        ImageData(id:"ramp_wheelchair",type: "wheelchair", imageName: "ramp_wheelchair", tag: "ramp:bicycle", optionName: LocalizedStrings.questStepsRampWheelchair.localized),
    ]
    var body: some View {
        VStack (alignment: .leading){
            QuestionHeader(icon: Image("ic_quest_steps_ramp"), title: LocalizedStrings.questDetermineSidewalkWidth.localized, subtitle: "North 88th Street").padding(.bottom,10)
            VStack(alignment: .leading){
                Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 2, isLabelBelow: false, imageData: imageData, isImageRotated: false, isDisplayImageOnly: false, onTap: { (type, tag) in
                    print("Clicked: \(type), Tag: \(tag)")}, selectedImage: $selectedImage)
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
    StepsRampForm()
}
