//
//  TactilePavingSteps.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI

class TactilePavingSteps :Quest {
    var title: String = "Tactile Paving Steps"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "steps_tactile_paving.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(TactilePavingStepsForm())
    var relationData: Any? = nil
    func onAnswer(answer: TactilePavingStepsAnswer) {
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    typealias AnswerClass = TactilePavingStepsAnswer
}

enum TactilePavingStepsAnswer: String {
    case yes = "yes"
    case no = "no"
    case top = "partial"
    case bottom = "incorrect"
}
