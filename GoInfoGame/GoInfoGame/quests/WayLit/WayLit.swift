//
//  WayLit.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class WayLit: QuestBase, Quest {
    
    var title: String = "Way Lit"
    var filter: String = """
    ways with
            (
              highway ~ \(WayLit.litResidentialRoads.joined(separator: "|"))
              or highway ~ \(WayLit.litNonResidentialRoads.joined(separator: "|")) and
              (
                sidewalk ~ both|left|right|yes|separate
                or ~"\((WayLit.maxSpeedTypeKeys.union(["maxspeed"])).joined(separator:"|"))" ~ ".*:(urban|.*zone.*|nsl_restricted)"
                or maxspeed <= 60
              )
              or highway ~ \(WayLit.litWays.joined(separator: "|"))
              or highway = path and (foot = designated or bicycle = designated)
            )
            and
            (
              !lit
              or lit = no and lit older today -8 years
              or lit older today -16 years
            )
            and (access !~ private|no or (foot and foot !~ private|no))
            and indoor != yes
            and ~path|footway|cycleway !~ link
    """
    var icon: UIImage = #imageLiteral(resourceName: "add_way_lit")
    var wikiLink: String = ""
    var changesetComment: String = ""

    var relationData: Element? = nil
   
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.SMALL )
    }
    typealias AnswerClass = YesNoAnswer
    
    private static let litResidentialRoads =  ["residential", "living_street", "pedestrian"]
    private  static let litNonResidentialRoads = [
        "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
        "secondary", "secondary_link", "tertiary", "tertiary_link", "unclassified", "service"
    ]
    private static let litWays = ["footway", "cycleway", "steps"]
    private  static let maxSpeedTypeKeys: Set<String> = [
        "source:maxspeed",
        "zone:maxspeed",
        "maxspeed:type",
        "zone:traffic"
    ]
    
    var _internalExpression: ElementFilterExpression?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            print("<>")
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    
    var form: AnyView {
        get{
            return AnyView(self.internalForm as! WayLitForm)
        }
    }
    
    override init() {
        super.init()
        self.internalForm = WayLitForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: YesNoAnswer) {
        
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = WayLit()
        q.relationData = element
        return q
    }
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
