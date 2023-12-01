//
//  QuestView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import SwiftUI

struct MultipleOptionsQuestView: View {
    var quest: any MultipleOptionsQuest
    var columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        VStack {
            Spacer()
            QuestTitleView(questViewModel: quest)
                .padding()
                .cornerRadius(10.0)
                        
            if let list = quest.options as? [IdentifiableQuestOption] {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10.0) {
                        ForEach(list) { option in
                            QuestOptionView(questOption: option)
                            
                        }
                    }
                }
                .padding()
            }
                        
            Button {
                
            } label: {
                Text("Cann't say")
            }
            .padding()
        }
    }
}

#Preview {
    MultipleOptionsQuestView(quest: StepsRampViewModel(networkRequest: URLSession()))
}
