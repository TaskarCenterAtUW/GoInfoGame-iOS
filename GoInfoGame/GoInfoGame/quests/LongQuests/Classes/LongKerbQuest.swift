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
    
    var filter: String = "nodes with barrier=kerb"
        
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
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LARGE)
    }
        
//    var sidewalkLongQuest: LongFormModel {
//        return QuestsRepository.shared.sideWalkLongQuestModel!
//    }
//    
    override init() {
        super.init()
        print("kerb LONG QUEST -")
        self.internalForm = LongForm(elementType: .kerb)
    }
    
    var relationData: Element? = nil
    
    func onAnswer(answer: [String : String]) {
        
    }
        
    var questId: String = "312"
    
    func copyWithElement(element: Element) -> any Quest {
        let quest = LongKerbQuest()
        quest.relationData = element
        return quest
    }
}
