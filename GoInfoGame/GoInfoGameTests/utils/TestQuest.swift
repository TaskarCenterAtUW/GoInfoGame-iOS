//
//  TestQuest.swift
//  GoInfoGameTests
//
//  Created by Naresh Devalapally on 1/22/24.
//

import Foundation
// Simple test quest
@testable import GoInfoGame
import UIKit
import SwiftUI
@testable import osmparser



class TestQuest : Quest {
    func onAnswer(answer: String) {
         
    }
    
    typealias AnswerClass = String
    
    var title: String = ""
    
    var filter: String = """
    nodes with
                (highway=bus_stop and public_transport!=stop_position)
                 and !lit
"""
    /*
     ["ref": "74078", "source": "King County GIS", "public_transport": "platform", "highway": "bus_stop", "name": "NE 124th St & 107th Pl NE", "gtfs:dataset_id": "KCGIS", "bus": "yes", "gtfs:stop_id": "74078"]
     ["source": "King County GIS", "bus": "yes", "highway": "bus_stop", "gtfs:stop_id": "74078", "public_transport": "platform", "ref": "74078", "gtfs:dataset_id": "KCGIS", "name": "NE 124th St & 107th Pl NE"]
     */
    
    var icon: UIImage = #imageLiteral(resourceName: "add_way_lit.pdf")
    
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    var form: AnyView = AnyView(YesNoView())
    
    var relationData: Any?
    
    var displayUnit: GoInfoGame.DisplayUnit {
        DisplayUnit(title: "", description: "", parent: self, sheetSize: .MEDIUM)
    }
    
    func isApplicable(element:Element) ->  Bool {
        do {
            let elementFilter = try filter.toElementFilterExpression()
            return elementFilter.matches(element: element)
        } catch (let error){
            print(error)
            return false
        }
    }
    
}
