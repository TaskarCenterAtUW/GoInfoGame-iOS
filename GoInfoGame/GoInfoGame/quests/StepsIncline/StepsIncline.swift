//
//  StepsIncline.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class StepsIncline: QuestBase, Quest {
    
    typealias AnswerClass = StepsInclineDirection
    
    var title: String = "StepsIncline"
    
    var filter: String = """
        ways with highway = steps
         and (!indoor or indoor = no)
         and area != yes
         and access !~ private|no
         and !incline
    """
    
    var icon: UIImage = #imageLiteral(resourceName: "steps.pdf")
    
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    var relationData: Element? = nil
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
    
    var _internalExpression: ElementFilterExpression?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! StepsInclineForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = StepsInclineForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: StepsInclineDirection) {
         
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = StepsIncline()
        q.relationData = element
        return q
    }
    
}

enum StepsInclineDirection {
    case up
    case down
    
}
