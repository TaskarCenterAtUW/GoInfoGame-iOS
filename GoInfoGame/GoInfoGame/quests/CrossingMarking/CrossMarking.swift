//
//  CrossMarking.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 19/01/24.
//

import Foundation
import UIKit
import SwiftUI

class CrossMarking :Quest {
    func onAnswer(answer: CrossingAnswer) {
        
    }
    var title: String = "Cross Marking"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(CrossMarkingForm())
    var relationData: Any? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    typealias AnswerClass = CrossingAnswer
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
