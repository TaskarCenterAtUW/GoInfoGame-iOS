//
//  CrossingKerbHeightForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 22/02/24.
//

import SwiftUI

struct CrossingKerbHeightForm: View, QuestForm {
    var action: ((KerbHeightTypeAnswer) -> Void)?
    typealias AnswerClass = KerbHeightTypeAnswer
    @State private var selectedImage:[String] = []
    @State private var showOtherAlert = false
    @State private var showAlert = false
    
    @Environment(\.presentationMode) var presentationMode

    let imageData: [ImageData] = [
        ImageData(id:"kerb_height_raised",type: "raised", imageName: "kerb_height_raised", tag: "raised", optionName: LocalizedStrings.questKerbHeightRaised.localized),
        ImageData(id:"kerb_height_lowered",type: "lowered", imageName: "kerb_height_lowered", tag: "lowered", optionName: LocalizedStrings.questKerbHeightLowered.localized),
        ImageData(id:"kerb_height_flush",type: "flush", imageName: "kerb_height_flush", tag: "flush", optionName: LocalizedStrings.questKerbHeightFlush.localized),
        ImageData(id:"kerb_height_lowered_ramp",type: "lowered", imageName: "kerb_height_lowered_ramp", tag: "lowered_and_sloped", optionName: LocalizedStrings.questKerbHeightLoweredRamp.localized),
        ImageData(id:"kerb_height_no",type: "no", imageName: "kerb_height_no", tag: "no", optionName: LocalizedStrings.questKerbHeightNo.localized)
    ]
    
    var body: some View {
        ScrollView {
            VStack {
                    DismissButtonView {
                        withAnimation {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    QuestionHeader(icon: Image("kerb_type"), title: LocalizedStrings.questCrossingKerbHeightTitle.localized, subtitle: "").padding(.bottom,10)
                    VStack(alignment: .leading){
                        Text(LocalizedStrings.selectOne.localized).font(.caption).foregroundColor(.gray)
                        ImageGridItemView(gridCount: 2, isLabelBelow: false, imageData: imageData, isImageRotated: false, isDisplayImageOnly: false, isScrollable: false, allowMultipleSelection: false, onTap: { (selectedImage) in
                        }, selectedImages: $selectedImage)
                        Divider()
                        HStack() {
                            Spacer()
                            Button {
                                showOtherAlert = true
                            } label: {
                                Text(LocalizedStrings.otherAnswers.localized).foregroundColor(.orange)
                            }
                            Spacer()
                            if !selectedImage.isEmpty {
                                Button() {
                                    let answer = CrossingKerbHeightAnswer.fromString(selectedImage.first ?? "")
                                    action?(answer ?? CrossingKerbHeightAnswer.none)
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
                    
                }
        }
            
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
}

#Preview {
    CrossingKerbHeightForm()
}
