//
//  CrossMarking.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser
// This is to figure out what type of marking is there for the crossing
class CrossMarking: QuestBase, Quest {
    var questId: String = "10"
    
    typealias AnswerClass = CrossingAnswer
    var _internalExpression: ElementFilterExpression?
    var title: String = "Cross Marking"
    var filter: String = "ways with highway=footway and footway=crossing and !crossing"
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize:.MEDIUM )
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
            return AnyView(self.internalForm as! CrossMarkingForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = CrossMarkingForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: CrossingAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["crossing":answer.rawValue], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = CrossMarking()
        q.relationData = element
        return q
    }
}

enum CrossingAnswer: String {
    case yes = "Yes"
    case no = "No"
    case none = "none"
}

struct TextItem<T> {
    let value: T
    let titleId: String
}
