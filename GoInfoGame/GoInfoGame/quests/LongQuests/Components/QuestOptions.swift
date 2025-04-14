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
            let columns = [
                GridItem(.flexible(), spacing: 30),
                GridItem(.flexible(), spacing: 30),
                GridItem(.flexible(), spacing: 30),
            ]

            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(options, id: \.id) { option in
                            Button(action: {
                                selectedAnswerId = option.id
                                onChoiceSelected(option)
                            }) {
                                VStack(spacing: 8) {
                                    if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                        LongFormImageView(
                                            urlString: imageUrl,
                                            width: 100,
                                            height: 100,
                                            id: option.id,
                                            label: option.choiceText,
                                            isSelected: currentAnswer == option.value
                                        )
                                        .cornerRadius(12)
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
                                }
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 2, y: 2)
                            }
                        }
                    }

                    // Place follow-up button separately after the grid
                    if let selected = options.first(where: { $0.id == selectedAnswerId }),
                       selected.choiceFollowUp != nil {
                        Button(action: {
                            uploadPhoto(true)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)

                                Text(selected.choiceFollowUp ?? "Upload a picture")
                                    .font(.custom("Lato-Regular", size: 13))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(8)
                            .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 2, y: 2)
                        }
                    }
                }
                .padding()
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
