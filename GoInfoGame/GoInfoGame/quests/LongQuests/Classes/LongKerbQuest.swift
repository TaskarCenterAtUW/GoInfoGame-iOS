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
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    
    var title: String = ""
    
    var filter: String = """
    nodes with
      !kerb
      or kerb ~ yes|unknown
      or kerb !~ no|rolled and kerb older today -8 years
"""
        
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
    var form:  AnyView {
        get{
            return AnyView(self.internalForm as! LongForm)
        }
    }
    
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LARGE)
    }
    
    override init() {
        super.init()
        self.internalForm = LongForm()
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
