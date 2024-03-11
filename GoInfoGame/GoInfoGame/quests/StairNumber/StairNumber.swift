//
//  StairNumber.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class StairNumber: QuestBase, Quest {
    typealias AnswerClass = Int
    var relationData: Element? = nil
    var _internalExpression: ElementFilterExpression?
    var title: String = "Stair Number"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "steps_count")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! StairNumberForm)
        }
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: LocalizedStrings.questStairs.localized,parent: self,sheetSize:.MEDIUM )
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
    
    override init() {
        super.init()
        self.internalForm = StairNumberForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: Int) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["step_count":"\(answer)"], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = StairNumber()
        q.relationData = element
        return q
    }
}
