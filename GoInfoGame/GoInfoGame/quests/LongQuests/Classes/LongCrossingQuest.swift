//
//  LongCrossingQuest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 07/08/24.
//

import Foundation
import osmparser
import SwiftUI

class LongCrossingQuest: QuestBase, Quest {
    var icon: UIImage = #imageLiteral(resourceName: "pedestrian")
    
    var title: String = ""
    
    var filter: String = "ways with (highway=footway and footway=crossing) and !ext:gig_complete"
        
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
    var form:  AnyView {
        get{
            return AnyView(self.internalForm as! LongForm)
        }
    }
    
    var _internalExpression: ElementFilterExpression?
    
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
    
//    var sidewalkLongQuest: LongFormModel {
//        return QuestsRepository.shared.sideWalkLongQuestModel!
//    }
//    
    override init() {
        super.init()
        self.internalForm = LongForm(elementType: .crossing, action: { tags in
            self.onAnswer(answer: tags)
        })
    }
    
    var relationData: Element? = nil
    
    func onAnswer(answer: [String : String]) {
        if let rData = self.relationData  {
            self.updateTags(id: rData.id, tags: answer, type: rData.type)
        }
    }
        
    var questId: String = "311"
    
    func copyWithElement(element: Element) -> any Quest {
        let quest = LongCrossingQuest()
        quest.relationData = element
        return quest
    }
}

