//
//  CrossingType.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 20/02/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class CrossingType: QuestBase, Quest {
    var title: String = "Crossing Type"
    var filter: String = """
        ways with highway = crossing
                  and footway = crossing
                  and (
                    !crossing
    """
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian_crossing.pdf")
    var wikiLink: String = ""
    var changesetComment: String = ""
    var relationData: Element? = nil
    var _internalExpression: ElementFilterExpression?
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.LARGE )
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
            return AnyView(self.internalForm as! CrossingTypeForm)
        }
    }
    override init() {
        super.init()
        self.internalForm = CrossingTypeForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    func onAnswer(answer: CrossingTypeAnswer) {
        if let rData = self.relationData {
            self.updateTags(id: rData.id, tags: ["crossing":answer.rawValue], type: rData.type)
        }
    }
    func copyWithElement(element: Element) -> any Quest {
        let q = CrossingIsland()
        q.relationData = element
        return q
    }
    typealias AnswerClass = CrossingTypeAnswer
}

enum CrossingTypeAnswer: String {
    case trafficSignals = "traffic_signals"
    case marked = "marked"
    case unmarked = "unmarked"
    case none = "none"
}
