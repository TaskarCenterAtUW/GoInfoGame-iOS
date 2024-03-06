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
    var subTitle: String? = ""
    var title: String = "Crossing Kerb Height"
    var _internalExpression: ElementFilterExpression?
    var relationData: Element? = nil
    //MARK: added nodes and ways filter as a single string. Need to change
    var filter: String = """
        nodes with
          highway = crossing
          and foot != no
          and crossing
          and !kerb:left and !kerb:right
          and (
            !kerb
            or kerb ~ yes|unknown
            or kerb !~ no|rolled and kerb older today -8 years
          )
     ways with
              highway and access ~ private|no
              or highway ~ footway|path|cycleway
    """
    var icon: UIImage = #imageLiteral(resourceName: "kerb_type.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! CrossingKerbHeightForm)
        }
    }
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.XLARGE )
    }
    typealias AnswerClass = CrossingKerbHeightAnswer
    override init() {
        super.init()
        self.internalForm = CrossingKerbHeightForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: CrossingKerbHeightAnswer) {
        var finalTags:[String:String] = [:]
        if let rData = self.relationData {
        /// expected tag for .kerbRamp & .lowered is same
        /// changing tag from "lowered_and_sloped" to "lowered"  for kerbRamp
            if answer == CrossingKerbHeightAnswer.kerbRamp {
                finalTags = ["kerb": "lowered_and_sloped"]
            } else {
                finalTags = ["kerb": "\(answer.osmValue)"]
            }
            self.updateTags(id: rData.id, tags: finalTags, type: rData.type)
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
        case .lowered:
            return "lowered"
        case .flush:
            return "flush"
        case .noKerb:
            return "no"
        case .none:
            return ""
        case .kerbRamp:
            return "lowered_and_sloped"
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
