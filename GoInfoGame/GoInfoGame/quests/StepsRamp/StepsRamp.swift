//
//  StepsRamp.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class StepsRamp: QuestBase, Quest {
    var title: String = "Steps Ramp"
    var filter: String = """
    ways with highway = steps
             and (!indoor or indoor = no)
             and access !~ private|no
             and (!conveying or conveying = no)
             and ramp != separate
             and (
               !ramp
               or (ramp = yes and !ramp:stroller and !ramp:bicycle and !ramp:wheelchair)
               or ramp = no and ramp older today -4 years
               or ramp older today -8 years
             )
    """
    var icon: UIImage = #imageLiteral(resourceName: "ic_quest_steps_ramp")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
    }
    typealias AnswerClass = StepsRampAnswer
    
    var _internalExpression: ElementFilterExpression?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! StepsRampForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = StepsRampForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: StepsRampAnswer) {
        
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = StepsRamp()
        q.relationData = element
        return q
    }
}

class StepsRampAnswer {
    let bicycleRamp: Bool
    let strollerRamp: Bool
    let wheelchairRamp: WheelchairRampStatus
    
    init(bicycleRamp: Bool, strollerRamp: Bool, wheelchairRamp: WheelchairRampStatus) {
        self.bicycleRamp = bicycleRamp
        self.strollerRamp = strollerRamp
        self.wheelchairRamp = wheelchairRamp
    }
    
    func hasRamp() -> Bool {
        return bicycleRamp || strollerRamp || wheelchairRamp != WheelchairRampStatus.NO
    }
}

enum  WheelchairRampStatus {
    case YES
    case NO
    case SEPARATE
}
