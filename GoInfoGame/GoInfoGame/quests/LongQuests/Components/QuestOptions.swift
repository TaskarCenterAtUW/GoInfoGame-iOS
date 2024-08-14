//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI

struct QuestOptions: View {
    
    let options: [QuestAnswerChoice]
    
    @State var selectedOption: String?
    
    var onChoiceSelected: (QuestAnswerChoice) -> ()
    
    var questType: QuestType
    
    @State private var textFieldValue: String = ""
    
    var body: some View {
        
        switch questType {
        case .exclusiveChoice:
            ScrollView {
                ForEach(options, id: \.id) { option in
                        Button(action: {
                            print("\(option.choiceText) pressed")
                            self.selectedOption = option.choiceText
                            onChoiceSelected(option)
                        }) {
                            Text(option.choiceText)
                                .font(.custom("Lato-Bold", size: 14))
                                .foregroundColor(selectedOption == option.choiceText ? Color.white : Color(red: 66/255, green: 82/255, blue: 110/255))
                                .padding()
                                .background(selectedOption == option.choiceText ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                                .cornerRadius(25)
                        }
                      
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
            }
        case .numeric:
                HStack {
                    TextField("Enter value", text: Binding(
                                   get: { textFieldValue },
                                   set: {
                                       textFieldValue = $0
                                       let answer = QuestAnswerChoice(value: textFieldValue, choiceText: textFieldValue, imageURL: "", choiceFollowUp: "")
                                       onChoiceSelected(answer)
                                   }
                               ))
                    .frame(width: 100)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)
                }
        case .excWithImg:
            HStack {}
//            LongImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromSurfaces, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: quest.questType.rawValue == "MultiplesChoice" ? true : false, onTap: { (selectedImage) in
//                  print("Selected long form image is \(selectedImage)")
//              }, selectedImages: $selectedImages)
        }
        
        
        
        
        
        
        
        

       }
}

//#Preview {
//    QuestOptions(options: ["Ashpalt", "Concrete", "Brick", "Others"], selectedOption: "")
//}
