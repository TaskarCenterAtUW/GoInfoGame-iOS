//
//  QuestTitleView.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/11/23.
//

import SwiftUI

struct QuestTitleView: View {
    var questViewModel: Quest
    var body: some View {
        VStack {
            Text(questViewModel.title)
                .font(.title)
            
        }
    }
}

#Preview {
    QuestTitleView(questViewModel: StepsRampViewModel(networkRequest: URLSession()))
}
