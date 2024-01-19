//
//  QuestsRepository.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
// singleton class that has all the quest type instances
class QuestsRepository {
    static let shared = QuestsRepository()
    private init() {}
    
    var applicableQuests: [ any Quest] = [
        SideWalkWidth(),
        HandRail(),
        StepsRamp(),
        StepsIncline(),
        StairNumber(),
        TactilePavingSteps(),
        WayLit(),
        BusStopLit(),
        CrossMarking()
    ]
    
    var displayQuests: [DisplayUnit] {
        self.applicableQuests.map { q in
            q.displayUnit
        }
    }
}
