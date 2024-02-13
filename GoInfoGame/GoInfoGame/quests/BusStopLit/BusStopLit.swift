//
//  BusStopLit.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 18/01/24.
//

import Foundation
import UIKit
import SwiftUI
import osmparser

class BusStopLit: QuestBase, Quest {
    var title: String = "Bus Stop Lit"
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
    var icon: UIImage = #imageLiteral(resourceName: "stop_lit")
    var wikiLink: String = ""
    var changesetComment: String = ""
    
    var relationData: Element? = nil
    var displayUnit: DisplayUnit {
        DisplayUnit(title: self.title, description: "",parent: self,sheetSize:.SMALL )
    }
    typealias AnswerClass = YesNoAnswer
    
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
            return AnyView(self.internalForm as! BusStopLitForm)
        }
    }
  
    override init() {
        super.init()
        self.internalForm = BusStopLitForm(action: { [self] answer in
            self.onAnswer(answer: answer)
        })
    }
    
    func onAnswer(answer: YesNoAnswer) {
        
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let q = BusStopLit()
        q.relationData = element
        return q
    }
}
