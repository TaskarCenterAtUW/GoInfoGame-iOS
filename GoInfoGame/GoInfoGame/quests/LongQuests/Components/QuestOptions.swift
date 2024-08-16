//
//  ShortAnswersWithoutImage.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 31/07/24.
//

import SwiftUI

struct QuestOptions: View {
    
    let options: [QuestAnswerChoice]
    
    @State var selectedOptions: [QuestAnswerChoice]
    
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
                        onChoiceSelected(option)
                        if let index = selectedOptions.firstIndex(where: { $0.id == option.id }) {
                            selectedOptions.remove(at: index)
                        } else {
                            selectedOptions = [option]
                        }
                    }) {
                        Text(option.choiceText)
                            .font(.custom("Lato-Bold", size: 14))
                            .foregroundColor(selectedOptions.contains(where: { $0.id == option.id }) ? Color.white : Color(red: 66/255, green: 82/255, blue: 110/255))
                            .padding()
                            .background(selectedOptions.contains(where: { $0.id == option.id }) ? Color(red: 135/255, green: 62/255, blue: 242/255) : Color(red: 245/255, green: 245/255, blue: 245/255))
                            .cornerRadius(25)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        case .numeric:
            HStack {
                TextField("Enter value", text: Binding(
                    get: {
                        if let selectedOption = selectedOptions.first(where: { $0.id == options.first?.id }) {
                            return selectedOption.value
                        }
                        return textFieldValue
                    },
                    set: {
                        textFieldValue = $0
                        let answer = QuestAnswerChoice(value: textFieldValue, choiceText: textFieldValue, imageURL: "", choiceFollowUp: "")
                        onChoiceSelected(answer)
                        if let index = selectedOptions.firstIndex(where: { $0.id == options.first?.id }) {
                            selectedOptions[index] = answer
                        } else {
                            selectedOptions.append(answer)
                        }
                    }
                ))
                .frame(width: 100)
                .padding(.horizontal)
                .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(Color(red: 135/255, green: 62/255, blue: 242/255)), alignment: .bottom)
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(UIKeyboardType.numberPad)
            }

        case .excWithImg:
            HStack {}
        }
    }
}
