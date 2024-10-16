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
                                    AsyncImage(url: URL(string: "https://media.istockphoto.com/id/1023284276/photo/black-asphalt-road-background-texture.jpg?s=612x612&w=0&k=20&c=ajA_pAZq95u_mprfKobNAGT_Q2OKn9Has28rhNxDRG0=")) { phase in
                                        switch phase {
                                        case .empty:
                                            // Display a placeholder while loading
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                        case .failure:
                                            // Display a fallback image or an empty view on failure
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .id(option.id)
                                }
                                
                                Text(option.choiceText)
                                    .font(.custom("Lato-Bold", size: 14))
                                    .foregroundColor(currentAnswer == option.value ? Color.white : Color(red: 66/255, green: 82/255, blue: 110/255))
                                    .padding()
                                    .background(currentAnswer == option.value ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                                    .cornerRadius(25)
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
