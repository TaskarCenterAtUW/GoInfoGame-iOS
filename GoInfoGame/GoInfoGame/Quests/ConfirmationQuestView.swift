//
//  ConfirmationQuestView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 30/11/23.
//

import SwiftUI

struct ConfirmationQuestView: View {
    var quest: any ConfirmationQuest
    var body: some View {
        VStack {
            Spacer()
            QuestTitleView(questViewModel: quest)
                .padding()
                .cornerRadius(10.0)
                        
            Button {
                
            } label: {
                Text(quest.accpetTitle)
            }
            .padding()
                        
            Button {
                
            } label: {
                Text(quest.rejectTitle)
            }
            .padding()
                        
            Button {
                
            } label: {
                Text("Cann't say")
            }
            .padding()
        }
    }
}

#Preview {
    ConfirmationQuestView(quest: CrossingIslandViewModel(networkRequest: URLSession()))
}
