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
                    .presentationDetents(getSheetSize(sheetSize: selectedText.sheetSize))
            }
            else{
                VStack {
                    Text("")
                }
            }
        }
    }
    @available(iOS 16.0, *)
    func getSheetSize(sheetSize:SheetSize) -> Set<PresentationDetent> {
        if selectedText?.sheetSize == .SMALL {
            return [.height(250)]
        }else if selectedText?.sheetSize == .LARGE {
          return [.height(600)]
        } else {
            return [.medium, .large]
        }
    }
}

#Preview {
    QuestsListUIView()
}
