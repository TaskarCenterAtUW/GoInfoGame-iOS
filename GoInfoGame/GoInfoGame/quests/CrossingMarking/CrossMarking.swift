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
    var title: String = "Cross Marking"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    typealias AnswerClass = CrossingAnswer
    
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
        
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = CrossMarking()
        q.relationData = element
        return q
    }
}

enum CrossingAnswer: String, CaseIterable {
    case yes
    case no
    case prohibited

    var description: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        case .prohibited: return "Prohibited"
        }
    }
}

struct TextItem<T> {
    let value: T
    let titleId: String
}
