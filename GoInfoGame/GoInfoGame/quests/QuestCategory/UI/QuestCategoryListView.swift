//
//  QuestCategoryListView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/01/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

struct QuestCategoryListView: View {
    @ObservedObject var questManager = QuestsRepository.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manage Quests")
                .font(.title)
                .bold()
                .padding(.top, 16)
                .padding(.horizontal)

            Text("Show all hidden elements on the map by individual item or type")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            SectionHeader(title: "TYPES")
            
            List {
                Section {
                    ForEach(questManager.allQuests.indices, id: \.self) { index in
                        HStack {
                            Image(uiImage: questManager.allQuests[index].quest.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)

                            Toggle(isOn: $questManager.allQuests[index].isDefault) {
                                Text(questManager.allQuests[index].quest.title.isEmpty ?
                                     questManager.longQuestModels[index].elementType :
                                     questManager.allQuests[index].quest.title)
                                .font(.caption)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()
            .frame(maxHeight: 300) // Limits List height to avoid full-screen expansion
        }
        .padding(.bottom, 16) // Padding for bottom safe area
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onDisappear {
            QuestsPublisher.shared.refreshQuest.send("")
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
