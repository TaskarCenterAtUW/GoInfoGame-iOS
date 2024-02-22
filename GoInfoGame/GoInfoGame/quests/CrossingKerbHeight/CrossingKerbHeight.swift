//
//  CrossingKerbHeight.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 22/02/24.
//

import Foundation
import SwiftUI
import UIKit
import osmparser

class CrossingKerbHeight: QuestBase, Quest {
    var title: String = "Crossing Kerb Height"
    var _internalExpression: ElementFilterExpression?
    var relationData: Element? = nil
    var filter: String = ""
    var icon: UIImage = #imageLiteral(resourceName: "kerb_type.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! CrossingKerbHeightForm)
        }
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    typealias AnswerClass = CrossingKerbHeightAnswer
    override init() {
        super.init()
        self.internalForm = CrossingKerbHeightForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: CrossingKerbHeightAnswer) {
        if let rData = self.relationData {
            let tags = ["kerb": "\(answer.osmValue)"]
            self.updateTags(id: rData.id, tags: tags, type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = StepsRamp()
        q.relationData = element
        return q
    }
}

enum CrossingKerbHeightAnswer: CaseIterable {
    case raised
    case lowered
    case flush
    case kerbRamp
    case noKerb
    case none
    
    var osmValue: String {
        switch self {
        case .raised:
            return "raised"
        case .lowered, .kerbRamp:
            return "lowered"
        case .flush:
            return "flush"
        case .noKerb:
            return "no"
        case .none:
            return ""
        }
    }
    static func fromString(_ osmValue: String) -> CrossingKerbHeightAnswer? {
        for caseEnum in allCases {
            if caseEnum.osmValue == osmValue {
                return caseEnum
            }
        }
        return nil
    }
}
