//
//  QuestCategoryListView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/01/25.
//

import SwiftUI

struct QuestCategoryListView: View {
    @ObservedObject var questManager = QuestsRepository.shared
    
    var body: some View {
        VStack {
            List {
                ForEach(questManager.allQuests.indices, id: \.self) { index in
                    HStack {
                        Button(action: {
                            questManager.allQuests[index].toggleIsDefault()
                        }) {
                            CheckBoxView(isChecked: questManager.allQuests[index].isDefault)
                        }
                        
                        Image(uiImage: questManager.allQuests[index].quest.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        Text(questManager.allQuests[index].quest.title == "" ? questManager.longQuestModels[index].elementType : questManager.allQuests[index].quest.title)
                    }
                }
            }
            .navigationTitle("Quest Selection")
            .onDisappear {
                QuestsPublisher.shared.refreshQuest.send("")
            }
        }
    }
}

struct CheckBoxView: View {
    
    let isChecked: Bool;
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
            .foregroundColor(isChecked ? Color(UIColor.systemBlue) : Color.secondary)
    }
}


#Preview {
    QuestCategoryListView()
}

