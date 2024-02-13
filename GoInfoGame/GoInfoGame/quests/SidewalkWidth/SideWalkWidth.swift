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
    
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! SideWalkWidthForm)
        }
    }
    
    var relationData: Element? = nil
    
    
    func onAnswer(answer: WidthAnswer)  {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["width":"11m"], type: rData.type) // TODO: Convert WidthAnswer to string
        }
    }
    typealias AnswerClass = WidthAnswer
    
    var _internalExpression: ElementFilterExpression?

    override init() {
        super.init()
        self.internalForm = SideWalkWidthForm { [self] answer in
            print("Wow!!")
            self.onAnswer(answer: answer)
            
        } onConfirm: { feet, inches, isConfirmAlert in
            print("Whatever") // Not needed but addeed for consistency
        }
        
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


