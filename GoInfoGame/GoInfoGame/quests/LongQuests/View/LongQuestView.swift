//
//  LongQuestView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 29/07/24.
//

import SwiftUI

struct LongQuestView: View {
    
    var quest: LongQuest
        
    @Binding var selectedChoice: QuestAnswerChoice?

    var uploadPhoto: (Bool) -> ()
  
    var questOptions: [QuestAnswerChoice] {
        return quest.questAnswerChoices ?? []
    }
    
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
            
            QuestOptions(options: questOptions, selectedChoice: $selectedChoice, questType: quest.questType, uploadPhoto: uploadPhoto)
        }
          .padding(.vertical, 5)
    }
    
}

#Preview {
    let jsonString = """
{
  "quest_id": 105,
  "quest_title": "What types of obstructions are present along this sidewalk?",
  "quest_description": "Select all applicable types of obstructions that are present along this sidewalk.",
  "quest_type": "MultipleChoice",
  "quest_tag": "ext:obstruction:type",
  "quest_answer_dependency": {
    "question_id": 104,
    "required_value": "yes"
  },
  "quest_answer_choices": [
    {
      "value": "bollard",
      "choice_text": "Bollard",
      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/bollard_2_square.png"
    },
    {
      "value": "mailbox",
      "choice_text": "Mailbox",
      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/mailbox_landscape.png"
    },
    {
      "value": "pole",
      "choice_text": "Utility Pole",
      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/utility_2_square.png"
    },
    {
      "value": "waste_bin",
      "choice_text": "Trash Can",
      "image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/sidewalk/obstruction/waste_bin_square.png"
    },
    {
      "value": "other",
      "choice_text": "Other obstruction",
      "choice_follow_up": "Please take a photo of the obstruction."
    }
  ]
}
"""
    if let longQeust = try? JSONDecoder().decode(LongQuest.self, from: jsonString.data(using: .utf8)!) {
        LongQuestView(quest: longQeust, selectedChoice: .constant(nil), uploadPhoto: { s in
        
            })
    }
}
