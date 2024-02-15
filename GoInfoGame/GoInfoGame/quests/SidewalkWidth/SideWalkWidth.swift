//
//  SideWalkWidth.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class SideWalkWidth : QuestBase, Quest {
    typealias AnswerClass = WidthAnswer
    var _internalExpression: ElementFilterExpression?
    var relationData: Element? = nil
    var title: String = "Side Walk Width"
    var filter: String = """
                        ways with
                        ( highway = footway
                        or foot = yes)
                        and !width
                        """
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk-width-img")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }else {
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! SideWalkWidthForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = SideWalkWidthForm { [self] answer in
            self.onAnswer(answer: answer)
        }
    }
    
    func onAnswer(answer: WidthAnswer)  {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["width":answer.width], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) ->  any Quest {
        let q = SideWalkWidth()
        q.relationData = element
        return q
    }
}

class WidthAnswer {
    let width : String
    let units: String
    let isARMeasurement : Bool
    init(width: String, units: String, isARMeasurement: Bool) {
        self.width = width
        self.units = units
        self.isARMeasurement = isARMeasurement
    }
}
