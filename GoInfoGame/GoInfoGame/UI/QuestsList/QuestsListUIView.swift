//
//  QuestsListUIView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 04/01/24.
//

import SwiftUI
extension String: Identifiable {
    public var id: String { return self }
}
struct QuestsListUIView: View {
    @State private var selectedText: Ques?
    @ObservedObject var viewModel = QuestsVM()
    
    var body: some View {
        List{
            if #available(iOS 15.0, *) {
                Section(LocalizedStrings.questionsList.localized){
                    ForEach(viewModel.quests, id: \.self) { selectedQues in
                        Button(action: {
                            selectedText = selectedQues
                        }) {
                            Text(selectedQues.subtitle)
                        }
                    }
                }
            } else {
                // Fallback on earlier versions
                Text(LocalizedStrings.questionsList.localized)
            }
        }.sheet(item: $selectedText) { selectedText in
            if #available(iOS 16.0, *) {
                QuestAndDescriptionView(quest: selectedText)
                    .presentationDetents([.medium, .large])
            }
            else{
                VStack {
                    Text("")
                }
            }
        }
    }
}

#Preview {
    QuestsListUIView()
}
