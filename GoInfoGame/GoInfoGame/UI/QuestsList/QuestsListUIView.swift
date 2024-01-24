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
