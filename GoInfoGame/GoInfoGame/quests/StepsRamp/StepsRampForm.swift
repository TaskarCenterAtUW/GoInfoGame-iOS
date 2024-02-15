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
    typealias AnswerClass = StepsRampAnswer
    @State private var selectedImage:[String] = []
    @State private var showAlert = false
    @State private var showWheelchairAlert = false
    let imageData: [ImageData] = [
        ImageData(id:"ramp_none",type: "none", imageName: "ramp_none", tag: "none", optionName: LocalizedStrings.questStepsRampNone.localized),
        ImageData(id:"ramp_bicycle",type: "bicycle", imageName: "ramp_bicycle", tag: "ramp:bicycle", optionName: LocalizedStrings.questStepsRampBicycle.localized),
        ImageData(id:"ramp_stroller",type: "stroller", imageName: "ramp_stroller", tag: "ramp:stroller", optionName: LocalizedStrings.questStepsRampStroller.localized),
        ImageData(id:"ramp_wheelchair",type: "wheelchair", imageName: "ramp_wheelchair", tag: "ramp:wheelchair", optionName: LocalizedStrings.questStepsRampWheelchair.localized),
    ]
    var body: some View {
        VStack (alignment: .leading){
            QuestionHeader(icon: Image("ic_quest_steps_ramp"), title: LocalizedStrings.questDetermineSidewalkWidth.localized, subtitle: "North 88th Street").padding(.bottom,10)
            VStack(alignment: .leading){
                Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                ImageGridItemView(gridCount: 2, isLabelBelow: false, imageData: imageData, isImageRotated: false, isDisplayImageOnly: false, isScrollable: false, allowMultipleSelection: true, onTap: { (selectedImage) in
                    print("Clicked Tag: \(selectedImage)")
                }, selectedImages: $selectedImage)
                
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
                    if !selectedImage.isEmpty {
                        Button() {
                            /// applying final selected answer
                            if selectedImage.contains("ramp:wheelchair") {
                                showWheelchairAlert = true
                            }else {
                                //TODO: none/bicycle/stroller type answer
                                let answer = StepsRampAnswer(bicycleRamp: true, strollerRamp: true, wheelchairRamp: .NO)
                                action?(answer)
                            }
                        }label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Font.system(size: 40))
                                .foregroundColor(.orange)
                        }
                        /// displayed only when selected answers contains wheelchair
                        .alert(LocalizedStrings.questStepsRampSeparateWheelchair.localized, isPresented: $showWheelchairAlert) {
                            Button(LocalizedStrings.questStepsRampSeparateWheelchairConfirm.localized.uppercased(), action: {
                                //TODO: wheelchair type answer separate
                            })
                            Button(LocalizedStrings.questStepsRampSeparateWheelchairDecline.localized.uppercased(), action: {
                                //TODO: wheelchair type answer not separate
                            })
                            /// no action to be taken
                            Button(LocalizedStrings.questGenericConfirmationNo.localized, role: .cancel, action: {})
                        }
                    }
                }.padding(.top,10)
            } .padding()
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
