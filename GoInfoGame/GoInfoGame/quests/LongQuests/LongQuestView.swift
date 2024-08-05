//
//  LongQuestView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/07/24.
//

import SwiftUI

struct LongQuestView: View {
    
    var quest: LongQuest
    
    var onChoiceSelected: (QuestAnswerChoice) -> ()
  
    var questOptions: [QuestAnswerChoice] {
        return quest.questAnswerChoices
    }
    
    let imagesFromSurfaces: [LongImageData] = SELECTABLE_WAY_SURFACES.compactMap { surfaceString in
        if let surface = Surface(rawValue: surfaceString) {
            return LongImageData(
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

    var body: some View {
        VStack(alignment: .leading) {
            Text(quest.questTitle)
                           .font(.custom("Lato-Bold", size: 16))
                           .foregroundColor(Color(red: 66/255, green: 82/255, blue: 110/255))
                           .padding([.bottom], 10)
            
                       Text(quest.questDescription)
                           .font(.custom("Lato-Regular", size: 12))
                           .foregroundColor(Color(red: 131/255, green: 135/255, blue: 155/255))
            
            switch quest.questType {
            case .exclusiveChoice:
                QuestOptions(options: questOptions, onChoiceSelected: { selectedChoice in
                    print("SELECTED CHOICE IS ---->>>\(selectedChoice)")
                    onChoiceSelected(selectedChoice)
                })
            case .numeric:
                HStack {
                    TextField("Enter value", text: .constant(""))
                    .frame(width: 100)
                    .padding(.horizontal)
                    .overlay(Rectangle().frame(height: 1).padding(.top, 25).foregroundColor(.orange), alignment: .bottom)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(UIKeyboardType.numberPad)

                }
            case .excWithImg:
                HStack {
                    
                }
//                LongImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromSurfaces, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: quest.questType.rawValue == "MultiplesChoice" ? true : false, onTap: { (selectedImage) in
//                      print("Selected long form image is \(selectedImage)")
//                  }, selectedImages: $selectedImage)
            }
          }
          .padding(.vertical, 5)
    }
    
}
