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
                selectedQuest.parent?.form.presentationDetents([.medium])
            } else {
                // Nothing here
            }

        }
    }
}


#Preview {
    QuestsListUIView()
}
