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


class SideWalkWidth : Quest {
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
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
    var form: AnyView = AnyView(SideWalkWidthForm())
    var relationData: Any? = nil
    func onAnswer(answer: WidthAnswer) {
    }
    typealias AnswerClass = WidthAnswer
    
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


