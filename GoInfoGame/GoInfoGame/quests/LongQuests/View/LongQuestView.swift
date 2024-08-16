//
//  LongQuestView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/07/24.
//

import SwiftUI

struct LongQuestView: View {
    
    @Binding var selectedAnswers: [UUID: UUID]
    
    var quest: LongQuest
    
    var onChoiceSelected: (QuestAnswerChoice) -> ()
  
    var questOptions: [QuestAnswerChoice] {
        return quest.questAnswerChoices
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
            
            QuestOptions(options: questOptions, selectedAnswerId: $selectedAnswers[quest.id], onChoiceSelected: { selectedChoice in
                print("SELECTED CHOICE IS ---->>>\(selectedChoice)")
                onChoiceSelected(selectedChoice)
            }, questType: quest.questType)
          }
          .padding(.vertical, 5)
    }
    
}
