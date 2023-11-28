//
//  StepsRampOption.swift
//  GoInfoGame
//
//  Created by Prashamsa on 28/11/23.
//

import Foundation

struct StepsRampOption: QuestOption {
    var tagValue: String
    var title: String
    var icon: String
    
    let ramp: StepsRamp

    init(ramp: StepsRamp) {
        self.ramp = ramp
        self.title = ramp.title()
        self.icon = ramp.iconName()
        self.tagValue = ramp.tagValue()
    }
}
