//
//  QuestsListUIView.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 04/01/24.
//

import SwiftUI

struct QuestsListUIView : View {
    let items: [ DisplayUnit] = QuestsRepository.shared.displayQuests
    @State var selectedQuest: DisplayUnit?
    var body: some View {
        List{
            ForEach(items) { item in
                Text(item.title)
                    .onTapGesture {
                        selectedQuest = item
                    }
            }
        } .sheet(item: $selectedQuest) { selectedQuest in
            
            if #available(iOS 16.0, *) {
                selectedQuest.parent?.form.presentationDetents(getSheetSize(sheetSize: selectedQuest.sheetSize ?? .MEDIUM))
            } else {
                // Nothing here
            }

        }
    }
}

//struct QuestsListUIView: View {
//    @State private var selectedText: (any Quest)?
//    @ObservedObject var viewModel = QuestsVM()
//    
//    var body: some View {
//        List{
//            if #available(iOS 15.0, *) {
//                Section(LocalizedStrings.questionsList.localized){
//                    
////                    ForEach(viewModel.quests) {_ in 
////                        
////                    }
////                    ForEach(viewModel.quests, id: \.self) { selectedQues in
////                        Button(action: {
////                            selectedText = selectedQues
////                        }) {
////                            Text(selectedQues.title)
////                        }
////                    }
//                }
//            } else {
//                // Fallback on earlier versions
//                Text(LocalizedStrings.questionsList.localized)
//            }
//        }
////        .sheet(item: $selectedText) { selectedText in
////            if #available(iOS 16.0, *) {
////               
////            }
////            else{
////                VStack {
////                    Text("")
////                }
////            }
////        }
//    }
    @available(iOS 16.0, *)
    func getSheetSize(sheetSize: SheetSize) -> Set<PresentationDetent> {
        if sheetSize == .SMALL {
            return [.height(250)]
        } else if sheetSize == .LARGE {
            return [.height(600)]
        } else {
            return [.medium, .large]
        }
    }
//}

#Preview {
    QuestsListUIView()
}
