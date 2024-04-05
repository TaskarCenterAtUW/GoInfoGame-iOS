//
//  TactilePavingSteps.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class TactilePavingSteps :QuestBase, Quest {
    
    var title: String = "Tactile Paving Steps"
    var filter: String = "ways with highway=steps and !surface"
    var icon: UIImage = #imageLiteral(resourceName: "steps_tactile_paving.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    typealias AnswerClass = YesNoAnswer
    
    var _internalExpression: ElementFilterExpression?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
//            print("<>")
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! TactilePavingStepsForm)
        }
    }

    override init() {
        super.init()
        self.internalForm = TactilePavingStepsForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: YesNoAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["tactile_paving":answer.rawValue], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = TactilePavingSteps()
        q.relationData = element
        return q
    }
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
