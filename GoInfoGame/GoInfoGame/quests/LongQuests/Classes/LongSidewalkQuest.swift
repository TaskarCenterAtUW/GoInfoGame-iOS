//
//  LongSidewalkQuest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 05/08/24.
//

import Foundation
import osmparser
import SwiftUI

class LongSidewalkQuest: QuestBase, Quest {
    var icon: UIImage = #imageLiteral(resourceName: "sidewalk_surface.pdf")
    
    var title: String = ""
    
    var filter: String = "ways with (highway=footway and footway=sidewalk) and !ext:gig_complete"
        
    var wikiLink: String = ""
    
    var changesetComment: String = ""
    
    typealias AnswerClass = [String:String]
    
//    private lazy var longForm: LongForm = {
//        LongForm(elementType: .sidewalk) { tags in
//            self.onAnswer(answer: tags)
//        }
//      }()
    
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
    
    override init() {
        super.init()
        print("SIDEWALK LONG QUEST ----")
        
        self.internalForm = LongForm(elementType: .sidewalk, action: { [self] tags in
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
        let quest = LongSidewalkQuest()
        quest.relationData = element
        return quest
    }
}


//class LongQuestBase {
//    
//    func loadLongQuests(from fileName: String) {
//            do {
//                if let loadedQuests = try FileStorageManager.shared.load(from: fileName) {
//                    self.longQuestModels = loadedQuests
//                } else {
//                    print("File not found")
//                }
//            } catch {
//                print("Failed to load file: \(error)")
//            }
//        }
//}
