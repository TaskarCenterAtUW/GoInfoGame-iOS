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
    
    @AppStorage("lowBandwidthMode") private var lowBandwidthMode: Bool = false
    
    @State private var isImageExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(quest.questTitle)
                .font(.custom("Lato-Bold", size: 16, relativeTo: .headline))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .padding([.bottom], 10)
                .accessibilityLabel(quest.getQuestTitleVoiceOver())
            
            if !lowBandwidthMode, let imageUrl = quest.questImageURL, !imageUrl.isEmpty {
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
                .accessibilityLabel("Image for \(quest.questTitle)")
            }
            
            Text(quest.questDescription)
                .font(.custom("Lato-Regular", size: 12, relativeTo: .body))
                .foregroundColor(Asset.Colors.huskyPurple.swiftUIColor)
                .multilineTextAlignment(.leading)
                .accessibilityLabel(quest.questDescription)
            if let questType = quest.questType {
                QuestOptions(quest: quest, selectedChoice: $selectedChoice, questType: questType, uploadPhoto: uploadPhoto)
            }
            
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
                    "quest_tag": "ext:crossing:description",
"quest_image_url": "https://raw.githubusercontent.com/TaskarCenterAtUW/tdei-tools/main/images/kerb/lowered_landscape.png"
                }
"""
    if let longQeust = try? JSONDecoder().decode(LongQuest.self, from: jsonString.data(using: .utf8)!) {
        LongQuestView(quest: longQeust, selectedChoice: .constant(nil), uploadPhoto: { s in
        
            })
    }
}
