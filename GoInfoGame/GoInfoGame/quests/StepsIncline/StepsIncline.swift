//
//  StepsIncline.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/18/24.
//

import Foundation
import UIKit
import SwiftUI

class StepsIncline: Quest{
    func onAnswer(answer: StepsInclineDirection) {
         
    }
    
    typealias AnswerClass = StepsInclineDirection
    
    var title: String = "StepsIncline"
    
    var filter: String = ""
    
    var icon: UIImage = #imageLiteral(resourceName: "steps.pdf")
    
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    var form: AnyView = AnyView(StepsInclineForm()) // temporary
    
    var relationData: Any? = nil
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self, sheetSize: .MEDIUM)
    }
    
    
}

enum StepsInclineDirection {
    case up
    case down
    
}