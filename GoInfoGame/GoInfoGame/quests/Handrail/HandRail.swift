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
    
    func onAnswer(answer: Bool) {
         
    }
    
    typealias AnswerClass = Bool
    
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
    
    var icon: UIImage = #imageLiteral(resourceName: "steps_handrail.pdf")
    
    var wikiLink: String = "Key:handrail"
    
    var changesetComment: String = "Specify whether steps have handrails"
    
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! HandRailForm)
        }
    }
    
    var relationData: Any? = nil
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize: .SMALL)
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
    override init() {
        super.init()
        self.internalForm = HandRailForm(action: { [self] yesNo in
            onAnswer(answer: yesNo)
        })
    }
}
