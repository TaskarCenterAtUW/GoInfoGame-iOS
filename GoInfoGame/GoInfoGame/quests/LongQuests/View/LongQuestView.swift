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
    
    var uploadPhoto: (Bool) -> ()
  
    var questOptions: [QuestAnswerChoice] {
        return quest.questAnswerChoices ?? []
    }
    
    @Binding var currentAnswer:String?
    
    @State private var isImageExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(quest.questTitle)
                .font(.custom("Lato-Bold", size: 16))
                .foregroundColor(Color(red: 66/255, green: 82/255, blue: 110/255))
                .padding([.bottom], 10)
            
            if let imageUrl = quest.questImageURL, !imageUrl.isEmpty {
                LongFormImageView(urlString: imageUrl, width: isImageExpanded ? 300 : 100, height: isImageExpanded ? 300 : 100)
                .onLongPressGesture(
                            minimumDuration: 0.5,
                            maximumDistance: 10,
                            pressing: { isPressing in
                                withAnimation {
                                    isImageExpanded = isPressing
                                }
                            },
                            perform: {}
                        )
            }
            
            Text(quest.questDescription)
                .font(.custom("Lato-Regular", size: 12))
                .foregroundColor(Color(red: 131/255, green: 135/255, blue: 155/255))
            
            QuestOptions(options: questOptions, selectedAnswerId: $selectedAnswers[quest.id], onChoiceSelected: { selectedChoice in
                onChoiceSelected(selectedChoice)
            }, currentAnswer: $currentAnswer, questType: quest.questType, uploadPhoto: uploadPhoto)
        }
          .padding(.vertical, 5)
    }
    
}

#Preview {
    let longQeust = LongQuest(questID: 14,
                              questTitle: "Does the length of this crossing allow for safe navigation?",
                              questDescription: "Determine whether this crossing is short enough to cross safely.",
                              questType: .exclusiveChoice,
                              questTag: "ext:crossing_adequate_length",
                              questAnswerChoices: [QuestAnswerChoice(value: "yes", choiceText: "Yes, this roadway can be crossed safely.", imageURL: nil, choiceFollowUp: nil),
                                                   QuestAnswerChoice(value: "no", choiceText: "No, this roadway is too wide to cross safely.", imageURL: nil, choiceFollowUp: nil)], questImageURL: nil, questAnswerValidation: nil, questAnswerDependency: nil, questUserAnswer: nil)
    
    
    
    LongQuestView(selectedAnswers: .constant([UUID(): UUID()]), quest: longQeust, onChoiceSelected: { qa in
        
    }, uploadPhoto: { s in
        
    }, currentAnswer: .constant(nil))
}
