//
//  SidewalkOverlay.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 10/12/23.
//

import Foundation
import UIKit
import CoreLocation
import SwiftUI
import RealmSwift

enum Sidewalk {
    case yes
    case no
    case separate
    case invalid
}

class SidewalkOverlay {

     var title: String { NSLocalizedString("overlay_sidewalk", comment: "") }
     var icon: UIImage? { UIImage(named: "ic_quest_sidewalk") }
     var changesetComment: String { "Specify whether roads have sidewalks" }
     var wikiLink: String { "Key:sidewalk" }

     func getStyledElements() -> [(RealmOPElement, PolylineStyle)] {
        let allElements = DatabaseConnector.shared.fetchValidHighway()

        var styledElements: [(RealmOPElement, PolylineStyle)] = []

        for element in allElements {
            let sidewalkStyle = getSidewalkStyle(element: element)
            styledElements.append((element, sidewalkStyle))
        }

        return styledElements
    }

     func createForm(element: RealmOPElement?)  {
//        guard let element = element else { return nil }
//
//        // Allow editing of all roads and all exclusive cycleways
//        if ALL_ROADS.contains(element.tags["highway"] ?? "") ||
//            createSeparateCycleway(tags: element.tags) == SeparateCycleway.EXCLUSIVE ||
//            createSeparateCycleway(tags: element.tags) == SeparateCycleway.EXCLUSIVE_WITH_SIDEWALK {
//            return SidewalkOverlayForm()
//        }
        //return nil
    }

    private func getFootwayStyle(element: RealmOPElement) -> PolylineStyle {
        let foot: String? = {
            if let footTag = element.tags.first(where: { $0.key == "foot" })?.value {
                return footTag
            } else {
                switch element.tags.first(where: { $0.key == "highway" })?.value {
                case "footway", "steps": return "designated"
                case "path": return "yes"
                default: return nil
                }
            }
        }()
        //prepare sidewalks path
        if let sidewalkSides = createSidewalkSides(tags: element.tags) {
            return getSidewalkStyle(element: element)
        } else
        if ["yes", "designated"].contains(foot) {
            return PolylineStyle(stroke: StrokeStyle(color: "skycolor",dashed: false))
        } else {
            return PolylineStyle(stroke: StrokeStyle(color: "invisblecolor", dashed: false))
        }
    }

    private func getSidewalkStyle(element: RealmOPElement) -> PolylineStyle {
        let sidewalkSides = createSidewalkSides(tags: element.tags)

        if sidewalkSides == nil {
            if sidewalkTaggingNotExpected(element: element) { //Check private here
                return PolylineStyle(stroke: StrokeStyle(color: "invisblecolor", dashed: false))
            }
        }

        return PolylineStyle(stroke: nil, strokeLeft: sidewalkSides?.left, strokeRight: sidewalkSides?.right)
    }

    private func createSidewalkSides(tags: RealmSwift.List<RealmOPElementTag>) -> SidewalkSides? {
        //prepare  sidewalk with elements types
        return SidewalkSides(left: StrokeStyle(color: "", dashed: true), right: StrokeStyle(color: "", dashed: true))
    }

    

    private func sidewalkTaggingNotExpected(element: RealmOPElement) -> Bool {
       return true
    }
    

    private var sidewalkStyle: StrokeStyle {
        return StrokeStyle(color: "", dashed: true)
    }
}
