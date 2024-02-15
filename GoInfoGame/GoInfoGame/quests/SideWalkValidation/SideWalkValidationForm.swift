//
//  SideWalkValidationForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 31/01/24.
//

import SwiftUI

struct SideWalkValidationForm: QuestForm ,View {
    var action: ((SideWalkValidationAnswer) -> Void)?
    
    typealias AnswerClass = SideWalkValidationAnswer
    @State private var showAlert = false
    @State private var selectedAnswer : SideWalkValidationAnswer = SideWalkValidationAnswer.noAnswerSelected
    @State private var selectedImage : [String] = []
    let SideWalksImageData: [ImageData] = [
        ImageData(id:SideWalkValidationAnswer.left.description,type: "yes", imageName: "select-left-side", tag: SideWalkValidationAnswer.left.description, optionName: LocalizedStrings.questSidewalkValueLeft.localized),
        ImageData(id:SideWalkValidationAnswer.right.description,type: "yes", imageName: "select-right-side", tag: SideWalkValidationAnswer.right.description, optionName: LocalizedStrings.questSidewalkValueRight.localized),
        ImageData(id:SideWalkValidationAnswer.both.description,type: "yes", imageName: "both", tag: SideWalkValidationAnswer.both.description, optionName: LocalizedStrings.questSidewalkValueBoth.localized),
        ImageData(id:SideWalkValidationAnswer.none.description,type: "no", imageName: "no-sidewalk", tag: SideWalkValidationAnswer.none.description, optionName: LocalizedStrings.questSidewalkValueNo.localized),
    ]
    let SidewalkOtherAnswerButtons = [
        ButtonInfo(id: 1, label: LocalizedStrings.cantSay.localized),
        ButtonInfo(id: 2, label: LocalizedStrings.questGenericAnswerDiffersAlongTheWay.localized),
        ButtonInfo(id: 3, label: LocalizedStrings.questSidewalkValueNoSidewalkAtAll.localized)
    ]
    
    var body: some View {
        ZStack{
            VStack (alignment: .leading){
                QuestionHeader(icon: Image("sidewalk"),
                               title: LocalizedStrings.questSidewalkTitle.localized,
                               subtitle: "Street")
                .padding(.bottom,10)
                VStack(alignment: .leading){
                    Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                    ImageGridItemView(gridCount: 2, isLabelBelow: true, imageData: SideWalksImageData, isImageRotated: false, isDisplayImageOnly: false, allowMultipleSelection: false, onTap: { (selectedImage) in
                        /// To select selected image option as SideWalkValidationAnswer
                        selectedAnswer = SideWalkValidationAnswer.fromString(selectedImage.first ?? "") ?? SideWalkValidationAnswer.none
                        print("Clicked Tag: \(selectedImage)")}, selectedImages: $selectedImage)
                    Divider()
                    HStack() {
                        Spacer()
                        Button {
                            showAlert = true
                        } label: {
                            Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                        }.frame(alignment: .center)
                        Spacer()
                        /// to display confirmation button to apply answer
                        /// enabled once selectedAnswer has non-noAnswerSelected option
                        if selectedAnswer.description != SideWalkValidationAnswer.noAnswerSelected.description {
                            Button() {
                            /// applying final selected answer
                                ///
                                action?(selectedAnswer)
                            }label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Font.system(size: 40))
                                    .foregroundColor(.orange)
                            }
                        }
                    }.padding(.top,10)
                }        .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2))
            }
            .padding()
            if showAlert {
                CustomAlert(title: "", content: {CustomVerticalButtonsList(buttons: SidewalkOtherAnswerButtons, selectionChanged: { selectedOtherAnswerOption in
                    /// To Dismiss alert when selectedButton value changes
                    showAlert = false
                    /// deselecting image option if any other answer is selected
                    selectedImage = [""]
                    print("selectedButton value", selectedOtherAnswerOption?.label ?? "")
                    /// To select other answers option as SideWalkValidationAnswer
                    selectedAnswer = SideWalkValidationAnswer.fromString(selectedOtherAnswerOption?.label ?? "", id: selectedOtherAnswerOption?.id) ?? SideWalkValidationAnswer.none
                })}, leftActionText: "", rightActionText: "", rightButtonAction: {}, height: 150, width: 200)
            }
        }.onTapGesture {
            showAlert = false
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    SideWalkValidationForm()
}
