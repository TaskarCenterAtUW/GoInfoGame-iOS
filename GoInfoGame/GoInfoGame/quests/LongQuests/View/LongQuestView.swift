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
                    "quest_id": 205,
                    "quest_title": "Additional crossing notes...",
                    "quest_description": "Add any additional observations you'd like to record about this crossing",
                    "quest_type": "TextEntry",
                    "quest_tag": "ext:crossing:description"
                }
"""
    if let longQeust = try? JSONDecoder().decode(LongQuest.self, from: jsonString.data(using: .utf8)!) {
        LongQuestView(quest: longQeust, selectedChoice: .constant(nil), uploadPhoto: { s in
        
            })
    }
}
