//
//  KerbHeightForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 02/04/24.
//

import Foundation
import SwiftUI

struct KerbHeightForm: View, QuestForm {
    var action: ((KerbHeightTypeAnswer) -> Void)?
    func applyAnswer(answer: KerbHeightTypeAnswer) {}
    typealias AnswerClass = KerbHeightTypeAnswer
    @State private var selectedAnswer: KerbHeightTypeAnswer = .none
    @State private var selectedImage: [String] = []
    
    @EnvironmentObject var contextualInfo: ContextualInfo
    
    @Environment(\.presentationMode) var presentationMode
    
    let KerbHeightImageData: [ImageData] = [
        ImageData(id:"kerb_height_raised", type: "raised", imageName: "kerb_height_raised", tag: "raised", optionName: LocalizedStrings.questKerbHeightRaised.localized),
        ImageData(id:"kerb_height_lowered", type: "lowered", imageName: "kerb_height_lowered", tag: "lowered", optionName: LocalizedStrings.questKerbHeightLowered.localized),
        ImageData(id:"kerb_height_flush", type: "flush", imageName: "kerb_height_flush", tag: "flush", optionName: LocalizedStrings.questKerbHeightFlush.localized),
        ImageData(id:"kerb_height_lowered_ramp", type: "lowered", imageName: "kerb_height_lowered_ramp", tag: "lowered_and_sloped", optionName: LocalizedStrings.questKerbHeightLoweredRamp.localized),
        ImageData(id:"kerb_height_no", type: "no", imageName: "kerb_height_no", tag: "no", optionName: LocalizedStrings.questKerbHeightNo.localized)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            DismissButtonView {
                withAnimation {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            QuestionHeader(icon: Image("kerb_type"), title: LocalizedStrings.questKerbHeightTitle.localized, contextualInfo: contextualInfo.info).padding(.bottom,10)
            
            ZStack {
                VStack(alignment: .leading) {
                    Text(LocalizedStrings.selectOne.localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ImageGridItemView(gridCount: 2,
                                      isLabelBelow: false,
                                      imageData: KerbHeightImageData,
                                      isImageRotated: false,
                                      isDisplayImageOnly: false,
                                      isScrollable: false,
                                      allowMultipleSelection: false,
                                      onTap: { selectedImage in },
                                      selectedImages: $selectedImage)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .shadow(color: .gray, radius: 2, x: 0, y: 2)
                    )
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if !selectedImage.isEmpty {
                            Button(action: {
                                let answer = KerbHeightTypeAnswer.fromString(selectedImage.first ?? "")
                                action?(answer ?? KerbHeightTypeAnswer.none)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Font.system(size: 40))
                                    .foregroundColor(.orange)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    KerbHeightForm()
}
