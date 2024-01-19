//
//  StairNumber.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI

class StairNumber :Quest {
    func onAnswer(answer: Int) {
    }
    var title: String = "Stair Number"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "steps_count")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(StairNumberForm())
    var relationData: Any? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    typealias AnswerClass = Int
}
