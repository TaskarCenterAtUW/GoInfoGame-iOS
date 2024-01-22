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
nodes, ways, relations with
    (
      public_transport = platform
      or (highway = bus_stop and public_transport != stop_position)
    )
    and physically_present != no and naptan:BusStopType != HAR
    and location !~ underground|indoor
    and indoor != yes
    and (!level or level >= 0)
    and (
      !lit
      or lit = no and lit older today -8 years
      or lit older today -16 years
    )
"""
    
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
