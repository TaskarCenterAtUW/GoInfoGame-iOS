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

class CrossMarking: QuestBase, Quest {
    typealias AnswerClass = CrossingAnswer
    var _internalExpression: ElementFilterExpression?
    var title: String = "Cross Marking"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: LocalizedStrings.questCrossingUnmarked.localized,parent: self,sheetSize:.MEDIUM )
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
    case prohibited = "Prohibited"
}

struct TextItem<T> {
    let value: T
    let titleId: String
}
