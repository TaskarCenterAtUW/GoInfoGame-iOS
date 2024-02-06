//
//  TactilePavingKerb.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/02/24.
//

import Foundation
import UIKit
import SwiftUI
typealias AnswerClass = Bool
class TactilePavingKerb :Quest {
    var title: String = "Tactile Paving Kerb"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "steps_tactile_paving")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(TactilePavingKerbForm())
    var relationData: Any? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.MEDIUM )
    }
    func onAnswer(answer: Bool) {
    }
}
