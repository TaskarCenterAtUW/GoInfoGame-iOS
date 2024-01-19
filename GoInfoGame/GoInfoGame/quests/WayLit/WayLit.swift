//
//  WayLit.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI

class WayLit: Quest{
    var title: String = "Way Lit"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "add_way_lit")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(WayLitForm())
    var relationData: Any? = nil
    func onAnswer(answer: WayLitOrIsStepsAnswer) {
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.SMALL )
    }
    typealias AnswerClass = WayLitOrIsStepsAnswer
}

protocol WayLitOrIsStepsAnswer {}

struct IsActuallyStepsAnswer: WayLitOrIsStepsAnswer {}

enum LitStatus {
    case yes
    case no
    case automatic
    case nightAndDay
    case unsupported
}

struct WayLitAnswer: WayLitOrIsStepsAnswer {
    var litStatus: LitStatus
}
