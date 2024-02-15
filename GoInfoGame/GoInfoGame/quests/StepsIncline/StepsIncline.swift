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
    var _internalExpression: ElementFilterExpression?
    var relationData: Element? = nil
    var icon: UIImage = #imageLiteral(resourceName: "steps.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var title: String = "StepsIncline"
    var filter: String = """
        ways with highway = steps
         and (!indoor or indoor = no)
         and area != yes
         and access !~ private|no
         and !incline
    """
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
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
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["incline":answer.rawValue], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = StepsIncline()
        q.relationData = element
        return q
    }
    
}

enum StepsInclineDirection: String {
    case up
    case down
}
