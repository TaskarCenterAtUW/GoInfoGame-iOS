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
    
    @State private var selectedImageURL: String? = nil

    var body: some View {
                
        switch questType {
        case .exclusiveChoice:
            let columns = [
                GridItem(.flexible(), spacing: 30),
                GridItem(.flexible(), spacing: 30),
                GridItem(.flexible(), spacing: 30),
            ]
            ZStack {
                ScrollView {
                    if let imageUrl = selectedImageURL {
                                   Color.black.opacity(0.4)
                                       .edgesIgnoringSafeArea(.all)
                                       .onTapGesture {
                                           selectedImageURL = nil
                                       }

                                   VStack {
                                       LongFormImageView(
                                             urlString: imageUrl,
                                                width: 300,
                                                height: 300,
                                                id: nil
                                        )
                                       Spacer()
                                       Button("Close") {
                                           selectedImageURL = nil
                                       }
                                       .padding()
                                       .background(Color.white)
                                       .cornerRadius(12)
                                   }
                                   .transition(.scale)
                                   .animation(.easeInOut, value: selectedImageURL)
                            }
                    
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
                                            .onLongPressGesture {
                                                selectedImageURL = imageUrl
                                            }
                                        } else {
                                            ZStack {
                                                Image("no_image")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                                
                                                Text(option.choiceText)
                                                    .font(.custom("Lato-Bold", size: 14))
                                                    .foregroundColor(Color.white)
                                                    .padding(.bottom, 8)
                                            }
                                            
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.white)
                                    
                                    
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
                                .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 2, y: 2)
                            }
                        }
                    }
                    .padding()
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
                    .padding(1)
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
