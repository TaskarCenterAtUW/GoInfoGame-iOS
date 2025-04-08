//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI

struct QuestOptions: View {
    
    let options: [QuestAnswerChoice]
    
    @Binding var selectedAnswerId: UUID?
    
    var onChoiceSelected: (QuestAnswerChoice) -> ()
    
    var questType: QuestType
    
    @State private var textFieldValue: String = ""
    
    @Binding var currentAnswer: String?
    
    var uploadPhoto: (Bool) -> ()
    
    @State private var isCameraPresented = false
    
    @State private var isImageExpanded = false
    
    @State private var expandedImageId: UUID? = nil

    var body: some View {
                
        switch questType {
        case .exclusiveChoice:
            ScrollView {
                ForEach(options, id: \.id) { option in
                        Button(action: {
                            selectedAnswerId = option.id
                            onChoiceSelected(option)
                        }) {
                            VStack(alignment: .leading, spacing: 10) {
                                if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                    LongFormImageView(urlString: imageUrl, width: expandedImageId == option.id ? 300 : 100, height: expandedImageId == option.id ? 300 : 100, id: option.id)
                                        .onLongPressGesture(
                                                    minimumDuration: 0.5,
                                                    maximumDistance: 10,
                                                    pressing: { isPressing in
                                                        withAnimation {
                                                            expandedImageId = isPressing ? option.id : nil
                                                        }
                                                    },
                                                    perform: {}
                                                )
                                }
                                
                                Text(option.choiceText)
                                    .font(.custom("Lato-Bold", size: 14))
                                    .foregroundColor(currentAnswer == option.value ? Color.white : Color(red: 66/255, green: 82/255, blue: 110/255))
                                    .padding()
                                    .background(currentAnswer == option.value ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                                    .cornerRadius(25)
                                
                                if option.choiceFollowUp != nil && currentAnswer == option.value {
                                    HStack {
                                        Button(action: {
                                            uploadPhoto(true)
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "camera")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white)
                                                
                                                Text(option.choiceFollowUp ?? "Upload a picture")
                                                    .font(.custom("Lato-Regular", size: 13))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                                            )
                                            .cornerRadius(8)
                                            .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 2, y: 2)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity)

                                }
                                
                            }
                        }
                      
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
            }
            
        case .numeric:
                HStack {
                    TextField("Enter value", text: Binding(
                                   get: { currentAnswer ?? "" },
                                   set: { newValue in
                                       textFieldValue = newValue
                                       let answer = QuestAnswerChoice(value: textFieldValue, choiceText: textFieldValue, imageURL: "", choiceFollowUp: "")
                                       onChoiceSelected(answer)
                                   }
                               ))
                    .frame(width: 100)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(Color(red: 135/255, green: 62/255, blue: 242/255)), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)
                }
            
//        case .excWithImg:
//            HStack {}
//            LongImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromSurfaces, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: quest.questType.rawValue == "MultiplesChoice" ? true : false, onTap: { (selectedImage) in
//                  print("Selected long form image is \(selectedImage)")
//              }, selectedImages: $selectedImages)
            }
       }
}

//#Preview {
//    QuestOptions(options: ["Ashpalt", "Concrete", "Brick", "Others"], selectedOption: "")
//}
