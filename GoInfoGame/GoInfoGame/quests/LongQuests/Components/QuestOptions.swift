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
    
    @State private var selectedImageText: String? = nil

    var body: some View {
                
        switch questType {
        case .exclusiveChoice:
            let columns = [
                GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
                GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
                GridItem(.flexible(minimum: 10.0, maximum: 100.0), spacing: 30),
            ]
            ZStack {
                ScrollView {
                    if let imageUrl = selectedImageURL {
                                   VStack {
                                       LongFormImageView(
                                             urlString: imageUrl,
                                                width: 300,
                                                height: 300
                                        )
                                       
                                       ZStack {
                                           let strokeOffsets: [(CGFloat, CGFloat)] = [
                                            (-1, -1), (1, -1),
                                            (-1, 1), (1, 1),
                                            (0, -1), (0, 1),
                                            (-1, 0), (1, 0)
                                           ]
                                           
                                           ForEach(0..<strokeOffsets.count, id: \.self) { i in
                                               let offset = strokeOffsets[i]
                                               Text(selectedImageText ?? "")
                                                   .font(.system(size: 15, weight: .bold))
                                                   .foregroundColor(.black)
                                                   .offset(x: offset.0, y: offset.1)
                                           }
                                           
                                           Text(selectedImageText ?? "")
                                               .font(.system(size: 15, weight: .bold))
                                               .foregroundColor(.white)
                                               .shadow(color: Color.black.opacity(0.7), radius: 4, x: 0, y: 2)
                                       }
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
                                    if selectedAnswerId == option.id {
                                        // Deselect
                                        selectedAnswerId = nil
                                        currentAnswer = nil
                                        selectedImageURL = nil
                                        selectedImageText = nil
                                        // Don't call onChoiceSelected if you want to ignore blank assignment
                                    } else {
                                        // Select
                                        selectedAnswerId = option.id
                                        currentAnswer = option.value
                                        onChoiceSelected(option)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                            LongFormImageView(
                                                urlString: imageUrl,
                                                width: 100,
                                                height: 100,
                                                label: option.choiceText
                                            )
                                        } else {
                                            ZStack {
                                                Image("no_image")
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.gray, lineWidth: 1)
                                                    )
                                                
                                                ZStack {
                                                    let strokeOffsets: [(CGFloat, CGFloat)] = [
                                                        (-1, -1), (1, -1),
                                                        (-1, 1), (1, 1),
                                                        (0, -1), (0, 1),
                                                        (-1, 0), (1, 0)
                                                    ]
                                                    
                                                    ForEach(0..<strokeOffsets.count, id: \.self) { i in
                                                        let offset = strokeOffsets[i]
                                                        Text(option.choiceText)
                                                            .font(.system(size: 15, weight: .bold))
                                                            .foregroundColor(.black)
                                                            .offset(x: offset.0, y: offset.1)
                                                            .frame(width: 100, height: 100)
                                                            .minimumScaleFactor(0.67) // min font size is 10
                                                    }
                                                    
                                                    Text(option.choiceText)
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .shadow(color: Color.black.opacity(0.7), radius: 4, x: 0, y: 2)
                                                        .frame(width: 100, height: 100)
                                                        .minimumScaleFactor(0.67) // min font size is 10
                                                }
                                            }
                                        }
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(currentAnswer == option.value ? Asset.Colors.accentPink.swiftUIColor : Color.clear, lineWidth: 3)
                                )
                                .onLongPressGesture {
                                    if let imageUrl = option.imageURL, !imageUrl.isEmpty {
                                        selectedImageURL = imageUrl
                                        selectedImageText = option.choiceText
                                    }
                                }
                            }
                        }

                        
                        // Place follow-up button separately after the grid
                        if let selected = selectedAnswerId.flatMap({ id in
                            options.first(where: { $0.id == id && $0.choiceFollowUp != nil })
                        }) {
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
                                    LinearGradient(gradient: Gradient(colors: [Asset.Colors.huskyPurple.swiftUIColor, Asset.Colors.accentPink.swiftUIColor]), startPoint: .leading, endPoint: .trailing)
                                )
                                .shadow(color: Color.gray.opacity(0.5), radius: 4, x: 2, y: 2)
                                .cornerRadius(9)
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

#Preview {
    QuestOptions(options: [QuestAnswerChoice(value: "asphalt", choiceText: "Asphalt", imageURL: "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/refs/heads/main/images/sidewalk/surface/asphalt_landscape.png", choiceFollowUp: nil),
                           QuestAnswerChoice(value: "no", choiceText: "No, this roadway is too wide to cross safely.", imageURL: nil, choiceFollowUp: nil)], selectedAnswerId: .constant(UUID()), onChoiceSelected: { qa in
        
    }, questType: GoInfoGame.QuestType.exclusiveChoice, currentAnswer: .constant("Binding<String?>")) { s in
        
    }
}
