//
//  QuestManager.swift
//  GoInfoGame
//
//  Created by Prashamsa on 04/12/23.
//

import Foundation
import SwiftUI

class QuestManager {
    private(set) var quests: [Quest] = []
    
    init() {
        
        self.quests = [
            CrossingIslandViewModel(),
            StepsRampViewModel()
        ]
    }
    
    func viewForQeust(quest: Quest) -> some View {
        if let q = quest as? ConfirmationQuest {
            return AnyView(ConfirmationQuestView(quest: q))
        } else if let q = quest as? MultipleOptionsQuest {
            return AnyView(MultipleOptionsQuestView(quest: q))
        }
        return AnyView(YetToImplementView())
    }
}
