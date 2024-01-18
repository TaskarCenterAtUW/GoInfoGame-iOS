//
//  BusStopLit.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI

class BusStopLit: Quest{
    func onAnswer(answer: Bool) {
    }
    var title: String = "Bus Stop Lit"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "stop_lit")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(BusStopLitForm())
    var relationData: Any? = nil
    func onAnswer(answer: WayLitOrIsStepsAnswer) {
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.SMALL )
    }
    typealias AnswerClass = Bool
}
