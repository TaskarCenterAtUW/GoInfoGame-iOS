//
//  LongGeneric.swift
//  GoInfoGame
//
//  Created by Achyut Kumar Maddela on 25/02/25.
//

import Foundation
import osmparser
import SwiftUI



class LongGenericQuest: QuestBase, Quest {
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    
    var title: String = ""
    
    var filter: String = "ways with (highway=footway and footway=sidewalk) and !ext:gig_complete"
        
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
    var form:  AnyView {
        get{
            return AnyView(self.internalForm as! LongForm)
        }
    }
    
    var _internalExpression: ElementFilterExpression?
    
    var _internalQueryString: String?
    
    var filterExpression: ElementFilterExpression? {
        if(_internalExpression != nil){
            return _internalExpression
        }
        else {
            let sideWalkLongQuestQuery = self._internalQueryString
            var sideWalkFilter = ""
            
            if let sideWalkLongQuestQuery = sideWalkLongQuestQuery {
                sideWalkFilter = sideWalkLongQuestQuery + " and !ext:gig_complete"
            } else {
                sideWalkFilter = "ways with (highway=footway and footway=sidewalk) and !ext:gig_complete"
            }
            _internalExpression = try? sideWalkFilter.toElementFilterExpression()
            return _internalExpression
        }
    }
    
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LONGFORM)
    }
    
    init(questId: String, questQuery:String) {
        super.init()
        self._internalQueryString = questQuery
        self.internalForm = LongForm(elementType: .generic,questID: questId, action: { [self] tags in
            self.onAnswer(answer: tags)
        })
    }
    
    override init() {
        super.init()
        
        self.internalForm = LongForm(elementType: .generic, action: { [self] tags in
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
        let questId = String(element.id)
        let quest = LongSidewalkQuest(questId: questId)
        quest.relationData = element
        return quest
    }
}
