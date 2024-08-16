//
//  LongKerbQuest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 07/08/24.
//

import Foundation
import osmparser
import SwiftUI

class LongKerbQuest: QuestBase, Quest {
    var icon: UIImage = #imageLiteral(resourceName: "kerb_type")
    
    var title: String = ""
    
    var filter: String = "nodes with barrier=kerb and !ext:gig_complete"
        
    var wikiLink: String = ""
    
    
    var _internalExpression: ElementFilterExpression?
    
    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
    var form:  AnyView {
        get{
            return AnyView(self.internalForm as! LongForm)
        }
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
    
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LONGFORM)
    }
            
    override init() {
        super.init()
        print("kerb LONG QUEST -")
        self.internalForm = LongForm(elementType: .kerb, action: { [self] tags in
            self.onAnswer(answer: tags)
        })
    }
    
    var relationData: Element? = nil
    
    func onAnswer(answer: [String : String]) {
        if let rData = self.relationData  {
            self.updateTags(id: rData.id, tags: answer, type: rData.type)
        }
    }
        
    var questId: String = "312"
    
    func copyWithElement(element: Element) -> any Quest {
        let quest = LongKerbQuest()
        quest.relationData = element
        return quest
    }
}
