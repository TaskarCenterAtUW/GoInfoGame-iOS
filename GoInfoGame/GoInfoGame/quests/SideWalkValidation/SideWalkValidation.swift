//
//  SideWalkValidation.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 31/01/24.
//

import Foundation
import SwiftUI

class SideWalkValidation :Quest {
    func onAnswer(answer: CrossingAnswer) {
    }
    typealias AnswerClass = CrossingAnswer
    var title: String = "Sidewalk Validation"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form : AnyView = AnyView(SideWalkValidationForm())
    var relationData: Any? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
}
enum SideWalkValidationAnswer: String, CaseIterable {
    case left
    case right
    case both
    case none

    var description: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .both: return "both"
        case .none: return "none"
        }
    }
}

let SideWalksImageData: [ImageData] = [
    ImageData(id:SideWalkValidationAnswer.left.description,type: "yes", imageName: "select-left-side", tag: SideWalkValidationAnswer.left.description, optionName: LocalizedStrings.questSidewalkValueLeft.localized),
    ImageData(id:SideWalkValidationAnswer.right.description,type: "yes", imageName: "select-right-side", tag: SideWalkValidationAnswer.right.description, optionName: LocalizedStrings.questSidewalkValueRight.localized),
    ImageData(id:SideWalkValidationAnswer.both.description,type: "yes", imageName: "steps-incline-up", tag: SideWalkValidationAnswer.both.description, optionName: LocalizedStrings.questSidewalkValueBoth.localized),
    ImageData(id:SideWalkValidationAnswer.none.description,type: "no", imageName: "no-sidewalk", tag: SideWalkValidationAnswer.none.description, optionName: LocalizedStrings.questSidewalkValueNo.localized),
]
