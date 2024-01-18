//
//  SideWalkWidth.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import UIKit
import SwiftUI


class SideWalkWidth : Quest {
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
    var title: String = "Side Walk Width"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk-width-img")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(SideWalkWidthForm())
    var relationData: Any? = nil
    func onAnswer(answer: WidthAnswer) {
    }
    typealias AnswerClass = WidthAnswer
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


