//
//  TactilePavingCrosswalk.swift
//  GoInfoGame
//
//  Created by Rajesh Kantipudi on 20/02/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class TactilePavingCrosswalk :QuestBase, Quest {
    
    var title: String = "Tactile Paving Crosswalk"
    var filter: String = "highway = crossing and foot != no and !tactile_paving"
    var icon: UIImage = #imageLiteral(resourceName: "tactile_crossing")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    typealias AnswerClass = YesNoAnswer
    
    var _internalExpression: ElementFilterExpression?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            print("<>")
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! TactilePavingCrosswalkForm)
        }
    }

    override init() {
        super.init()
        self.internalForm = TactilePavingCrosswalkForm(action: { [self] answer in
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

