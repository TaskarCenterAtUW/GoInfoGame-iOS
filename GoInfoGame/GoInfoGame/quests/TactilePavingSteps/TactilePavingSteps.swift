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
    var filter: String = """
    ways with highway = steps
             and surface ~ \(PavedTypes.anythingPaved.joined(separator: "|"))
             and (!conveying or conveying = no)
             and access !~ private|no
            and (
              !tactile_paving
              or tactile_paving = unknown
              or tactile_paving ~ no|partial|incorrect and tactile_paving older today -4 years
              or tactile_paving = yes and tactile_paving older today -8 years
            )
    """
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

struct PavedTypes {
    static let anythingFullyPaved: Set<String> = [
        "paved", "asphalt", "cobblestone", "cobblestone:flattened", "sett",
        "concrete", "concrete:plates", "paving_stones",
        "metal", "wood", "unhewn_cobblestone", "chipseal",
        "brick", "bricks", "cobblestone:flattened", "paving_stones:30",
    ]
    
    static let anythingPaved: Set<String> = anythingFullyPaved.union([
        "concrete:lanes"
    ])
}
