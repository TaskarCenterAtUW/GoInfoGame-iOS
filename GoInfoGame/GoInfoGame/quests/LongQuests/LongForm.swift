//
//  SidewalkLongForm.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/07/24.
//

import SwiftUI

struct LongForm: View {
    let form = dummyFormData
    @State private var selectedImage : [String] = []
    @Binding var feet: Int
    @Binding var inches: Int
    @Binding var isConfirmAlert: Bool

    
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

    var body: some View {
        List {
            ForEach(dummyFormData.quests) { quest in
                    
                    viewWithoutChild(quest: quest)
                    

                }
            
        }
        .listStyle(GroupedListStyle())
    }
    
    func viewWithChild(quest: LongQuest) -> some View {
        
        let imagesFromQuest: [LongImageData] = quest.questAnswerChoices.compactMap { choice in
                        LongImageData(
                            type: choice.value, imageName: choice.imageURL ?? "surface_asphalt",
                            tag: choice.value, optionName: choice.choiceText
                        )
                    }
        
      return VStack(alignment: .leading) {
            Text(quest.questTitle)
                .font(.headline)
            Text(quest.questDescription)
                .font(.subheadline)
            
          if quest.questType.rawValue == "ExclusiveChoice" {
              LongImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromQuest, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: quest.questType.rawValue == "MultiplesChoice" ? true : false, onTap: { (selectedImage) in
                    print("Selected long form image is \(selectedImage)")
                }, selectedImages: $selectedImage).frame(height: 350)

          } else if quest.questType.rawValue == "Numeric" {
                LongFormWidthView(feet: $feet, inches: $inches, isConfirmAlert: $isConfirmAlert)
            }
        }
        .padding(.vertical, 5)
            
        
        
    }
    
    func viewWithoutChild(quest: LongQuest) -> some View {
        let imagesFromQuest: [LongImageData] = quest.questAnswerChoices.compactMap { choice in
                        LongImageData(
                            type: choice.value, imageName: choice.imageURL ?? "surface_asphalt",
                            tag: choice.value, optionName: choice.choiceText
                        )
                    }
        
      return VStack(alignment: .leading) {
            Text(quest.questTitle)
                .font(.headline)
            Text(quest.questDescription)
                .font(.subheadline)
            
          if quest.questType.rawValue == "ExclusiveChoice" {
              LongImageGridItemView(gridCount: 3, isLabelBelow: true, imageData: imagesFromQuest, isImageRotated: false, isDisplayImageOnly: false, isScrollable: true, allowMultipleSelection: quest.questType.rawValue == "MultiplesChoice" ? true : false, onTap: { (selectedImage) in
                    print("Selected long form image is \(selectedImage)")
                }, selectedImages: $selectedImage).frame(height: 350)

          } else if quest.questType.rawValue == "Numeric" {
                LongFormWidthView(feet: $feet, inches: $inches, isConfirmAlert: $isConfirmAlert)

            }
        }
        .padding(.vertical, 5)
    }
}

#Preview {

    LongForm(feet: .constant(10), inches: .constant(10), isConfirmAlert: .constant(false))
}
