//
//  TactilePavingKerb.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 06/02/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

typealias AnswerClass = Bool
class TactilePavingKerb :Quest {
    var questId: String = "5"
    
    var relationData: Element? = nil
    func copyWithElement(element: Element) -> any Quest {
        let tactilePavingKerb = TactilePavingKerb()
        tactilePavingKerb.relationData = element
        return tactilePavingKerb
    }
    var title: String = "Tactile Paving Kerb"
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "steps_tactile_paving")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView = AnyView(TactilePavingKerbForm())
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid) - \(questId)",parent: self,sheetSize:.MEDIUM )
    }
    func onAnswer(answer: Bool) {
    }
}
