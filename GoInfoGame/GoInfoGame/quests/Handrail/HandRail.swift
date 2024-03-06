//
//  HandRail.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//
import UIKit
import SwiftUI
import Foundation
import osmparser

class HandRail: QuestBase,Quest {
    typealias AnswerClass = YesNoAnswer
    var _internalExpression: ElementFilterExpression?
    var relationData: Element? = nil
    var icon: UIImage = #imageLiteral(resourceName: "steps_handrail.pdf")
    var wikiLink: String = "Key:handrail"
    var changesetComment: String = "Specify whether steps have handrails"
    var title: String = "HandRail"
    var filter: String = """
        ways with highway = steps
        and (!indoor or indoor = no)
        and access !~ private|no
        and (!conveying or conveying = no)
        and (
            !handrail and !handrail:center and !handrail:left and !handrail:left
            or handrail = no and handrail older today -4 years
            or handrail older today -8 years
            or older today -8 years
        )
"""
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! HandRailForm)
        }
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize: .SMALL)
    }
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        } else {
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var subTitle: String? = ""
    
    override init() {
        super.init()
        self.internalForm = HandRailForm(action: { [self] yesNo in
            onAnswer(answer: yesNo)
        })
    }
    
    func onAnswer(answer: YesNoAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["handrail":answer.rawValue], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = HandRail()
        q.relationData = element
        return q
    }
}
