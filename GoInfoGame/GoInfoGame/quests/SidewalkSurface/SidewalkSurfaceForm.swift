//
//  SidewalkSurfaceForm.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 05/02/24.
//

import SwiftUI
// View representing a form for sidewalk surface selection
struct SidewalkSurfaceForm: QuestForm ,View {
    var action: ((SidewalkSurfaceAnswer) -> Void)?
    
    typealias AnswerClass = SidewalkSurfaceAnswer
    @State private var selectedImage : [String] = []
    @State private var showAlert = false
    @State private var selectedAnswer : SidewalkSurfaceAnswer = SidewalkSurfaceAnswer(value: SurfaceAndNote(surface: Surface.none,note: ""))
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var contextualInfo: ContextualInfo

    let imagesFromSurfaces: [ImageData] = SELECTABLE_WAY_SURFACES.compactMap { surfaceString in
        if let surface = Surface(rawValue: surfaceString) {
            return ImageData(
                id: surfaceString,
                type: surfaceString,
                imageName: surface.iconResId,
                tag: surface.rawValue,
                optionName:  surface.titleResId
            )
        } else {
            print("Invalid Surface: \(surfaceString)")
            return nil
        }
    }
    let SidewalkSurfaceOtherAnswerButtons = [
        ButtonInfo(id: 1, label: LocalizedStrings.cantSay.localized),
        ButtonInfo(id: 2, label: LocalizedStrings.questGenericAnswerDiffersAlongTheWay.localized),
    ]
    var body: some View {
        ZStack{
            VStack (alignment: .leading){
                DismissButtonView {
                    withAnimation {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                // Question header
                QuestionHeader(icon: Image("sidewalk_surface"),
                               title: LocalizedStrings.questSidewalkSurfaceTitle.localized,
                               contextualInfo: contextualInfo.info)
                .padding(.bottom,10)
                // Quest Body
                VStack(alignment: .leading){
                    Text(LocalizedStrings.select.localized).font(.caption).foregroundColor(.gray)
                    /// Grid view for displaying selectable surfaces
                    ImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromSurfaces, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: false, onTap: { (selectedImage) in
                        selectedAnswer = SidewalkSurfaceAnswer(value: SurfaceAndNote(surface: Surface(rawValue: selectedImage.first ?? ""),note: ""))
                        print("selectedAnswer:", selectedAnswer)
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
                        if selectedAnswer.value.surface != Surface.none {
                            Button() {
                            /// applying final selected answer
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
                CustomAlert(title: "", content: {CustomVerticalButtonsList(buttons: SidewalkSurfaceOtherAnswerButtons, selectionChanged: { selectedOtherAnswerOption in
                    /// To Dismiss alert when selectedButton value changes
                    showAlert = false
                    /// deselecting image option if any other answer is selected
                    selectedImage = [""]
                    print("selectedButton value", selectedOtherAnswerOption?.label ?? "")
                    /// To select other answers option as SidewalkSurfaceAnswer
                    selectedAnswer = SidewalkSurfaceAnswer(value: SurfaceAndNote(surface: Surface.none,note: selectedOtherAnswerOption?.label ?? ""))
                })}, leftActionText: "", rightActionText: "", leftButtonAction: {}, rightButtonAction: {}, height: 100, width: 200)
            }
        }.onTapGesture {
            showAlert = false
        }
        .allowsHitTesting(true)
    }
}

#Preview {
    SidewalkSurfaceForm()
}
