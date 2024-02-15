//
//  SideWalkValidation.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 31/01/24.
//

import Foundation
import SwiftUI
import osmparser

class SideWalkValidation: QuestBase, Quest {
    typealias AnswerClass = SideWalkValidationAnswer
    var title: String = "Sidewalk Validation"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! SideWalkValidationForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = SideWalkValidationForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: SideWalkValidationAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["sidewalk":answer.description], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = SideWalkValidation()
        q.relationData = element
        return q
    }
}

enum SideWalkValidationAnswer {
    case left
    case right
    case both
    case none
    case custom(ButtonInfo)
    case noAnswerSelected

    var description: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .both: return "both"
        case .none: return "none"
        case .custom(let buttonInfo): return buttonInfo.label
        case .noAnswerSelected: return "noAnswerSelected"
        }
    }
}

extension SideWalkValidationAnswer {
    static func fromString(_ string: String, id: Int? = nil) -> SideWalkValidationAnswer? {
        switch string.lowercased() {
        case "left":
            return .left
        case "right":
            return .right
        case "both":
            return .both
        case "none":
            return SideWalkValidationAnswer.none
        default:
            return .custom(ButtonInfo(id: id ?? 1, label: string))
        }
    }
}
