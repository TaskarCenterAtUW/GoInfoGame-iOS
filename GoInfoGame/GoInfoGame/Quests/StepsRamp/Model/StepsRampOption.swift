//
//  StepsRampOption.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import Foundation

class IdentifiableQuestOption: QuestOption, Identifiable {
    var tagValue: String = ""
    
    var title: String = ""
    
    var icon: String = ""
    
    
}

class StepsRampOption: IdentifiableQuestOption {
//    var tagValue: String
//    var title: String
//    var icon: String
    
    let ramp: StepsRamp

    init(ramp: StepsRamp) {
        self.ramp = ramp
        super.init()
        
        self.title = ramp.title()
        self.icon = ramp.iconName()
        self.tagValue = ramp.tagValue()
    }
}
