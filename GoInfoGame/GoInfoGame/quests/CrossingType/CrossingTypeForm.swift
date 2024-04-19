//
//  CrossingTypeForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 20/02/24.
//

import SwiftUI

struct CrossingTypeForm: View, QuestForm {
    var action: ((CrossingTypeAnswer) -> Void)?
    func applyAnswer(answer: CrossingTypeAnswer) {
    }
    typealias AnswerClass = CrossingTypeAnswer
    @State private var selectedAnswer:CrossingTypeAnswer = .none
    @State private var showAlert = false
    @State private var selectedImage:[String] = []
    @State private var showOtherAlert = false
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var contextualInfo: ContextualInfo

    let imageData: [ImageData] = [
        ImageData(id:"crossing_type_signals",type: "traffic_signals", imageName: "crossing_type_signals", tag: "traffic_signals", optionName: LocalizedStrings.questCrossingTypeSignalsControlled.localized),
        ImageData(id:"crossing_type_unmarked",type: "marked", imageName: "crossing_type_zebra", tag: "marked", optionName: LocalizedStrings.questCrossingTypeMarked.localized),
        ImageData(id:"crossing_type_zebra",type: "unmarked", imageName: "crossing_type_unmarked", tag: "unmarked", optionName: LocalizedStrings.questCrossingTypeUnmarked.localized),
    ]
    var body: some View {
        ZStack{
            VStack{
                DismissButtonView {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }.padding(.top,5)
                QuestionHeader(icon:Image("pedestrian_crossing"), title: LocalizedStrings.questCrossingTypeTitle.localized, contextualInfo: contextualInfo.info)
                VStack(alignment:.center){
                    VStack (alignment: .leading){
                        Text(LocalizedStrings.selectOne.localized).font(.caption).foregroundColor(.gray)
                        ImageGridItemView(gridCount: 3, isLabelBelow: false, imageData: imageData, isImageRotated: false, isDisplayImageOnly: false, isScrollable: false, allowMultipleSelection: false, onTap: { (selectedImage) in
                            selectedAnswer =  CrossingTypeAnswer(rawValue: selectedImage.first ?? "") ?? .none
                            print("selected crossing type tag ->",selectedAnswer.rawValue)
                        }, selectedImages: $selectedImage)
                    }
                    VStack() {
                        if selectedAnswer != .none {
                            Button() {
                                presentationMode.wrappedValue.dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                                    self.action?(selectedAnswer)
                                }
                            }label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Font.system(size: 40))
                                    .foregroundColor(.orange)
                            }
                        }
                    }.padding(.top,10)
                } .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }.padding()
            
            /// if user selects cant say option
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
    CrossingTypeForm()
}
