//
//  SettingsView.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 13/06/24.
//

import SwiftUI

struct SettingsView : View {
    let items: [ApplicableQuest] = QuestsRepository.shared.applicableQuests
    
    @ObservedObject var questManager = QuestsRepository.shared
  
    var body: some View {
          List {
              ForEach(0..<questManager.applicableQuests.count, id: \.self) { index in
                  HStack {
                      Image(uiImage: questManager.applicableQuests[index].quest.icon)
                          .resizable()
                          .aspectRatio(contentMode: .fit)
                          .frame(width: 30, height: 30) 
                      
                      Text(questManager.applicableQuests[index].quest.title)
                      Spacer()
                      Button(action: {
                          questManager.applicableQuests[index].toggleIsDefault()
                      }) {
                          CheckBoxView(isChecked: questManager.applicableQuests[index].isDefault ? true : false)
                      }
                  }
              }
          }
          .navigationTitle("Quest Selection")
          .onDisappear {
              print(items)
              QuestsPublisher.shared.refreshQuest.send("")
              
          }
      }
  }

#Preview {
    Group {
        CheckBoxView(isChecked: true)
        CheckBoxView(isChecked: true)
        CheckBoxView(isChecked: false)
        CheckBoxView(isChecked: false)
    }
}



struct CheckBoxView: View {
    
    let isChecked: Bool;
    
    var body: some View {
        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
            .foregroundColor(isChecked ? Color(UIColor.systemBlue) : Color.secondary)
    }
}
