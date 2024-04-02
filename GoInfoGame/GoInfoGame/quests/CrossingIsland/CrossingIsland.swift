//
//  CrossingIsland.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 20/02/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class CrossingIsland: QuestBase, Quest {
    typealias AnswerClass = YesNoAnswer
    var relationData: Element? = nil
    var _internalExpression: ElementFilterExpression?
    var icon: UIImage = #imageLiteral(resourceName: "ic_quest_pedestrian_crossing_island.pdf")
    var wikiLink: String = """
    ways with
          highway = footway
          and footway=traffic_island
          and !crossing:marking
    """
    var changesetComment: String = ""
    var title: String = "Crossing Island"
    var filter: String = ""
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.SMALL )
    }
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
            return AnyView(self.internalForm as! CrossingIslandForm)
        }
    }
  
    override init() {
        super.init()
        self.internalForm = CrossingIslandForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: YesNoAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["crossing:island":answer.rawValue], type: rData.type)
        }
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = CrossingIsland()
        q.relationData = element
        return q
    }
}
