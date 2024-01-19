//
//  StepsRamp.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI

class StepsRamp :Quest {
    var title: String = "Steps Ramp"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "ic_quest_steps_ramp")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(StepsRampForm())
    var relationData: Any? = nil
    func onAnswer(answer: StepsRampAnswer) {
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    typealias AnswerClass = StepsRampAnswer
}

class StepsRampAnswer {
    let bicycleRamp: Bool
    let strollerRamp: Bool
    let wheelchairRamp: WheelchairRampStatus
    
    init(bicycleRamp: Bool, strollerRamp: Bool, wheelchairRamp: WheelchairRampStatus) {
        self.bicycleRamp = bicycleRamp
        self.strollerRamp = strollerRamp
        self.wheelchairRamp = wheelchairRamp
    }
    
    func hasRamp() -> Bool {
        return bicycleRamp || strollerRamp || wheelchairRamp != WheelchairRampStatus.NO
    }
}

enum  WheelchairRampStatus {
    case YES
    case NO
    case SEPARATE
}
