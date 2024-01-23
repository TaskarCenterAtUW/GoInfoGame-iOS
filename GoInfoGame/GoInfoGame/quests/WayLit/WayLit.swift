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
    var filter: String = """
    ways with
            (
              highway ~ \(RoadTypes.litResidentialRoads.joined(separator: "|"))
              or highway ~ \(RoadTypes.litNonResidentialRoads.joined(separator: "|")) and
              (
                sidewalk ~ both|left|right|yes|separate
                or ~"\((MaxSpeedConstants.maxSpeedTypeKeys.union(["maxspeed"])).joined(separator:"|"))" ~ ".*:(urban|.*zone.*|nsl_restricted)"
                or maxspeed <= 60
              )
              or highway ~ \(RoadTypes.litWays.joined(separator: "|"))
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

struct RoadTypes {
    static let litResidentialRoads = ["residential", "living_street", "pedestrian"]
    
    static let litNonResidentialRoads = [
        "motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link",
        "secondary", "secondary_link", "tertiary", "tertiary_link", "unclassified", "service"
    ]
    
    static let litWays = ["footway", "cycleway", "steps"]
}

struct MaxSpeedConstants {
    static let maxSpeedTypeKeys: Set<String> = [
        "source:maxspeed",
        "zone:maxspeed",
        "maxspeed:type",
        "zone:traffic"
    ]
}
