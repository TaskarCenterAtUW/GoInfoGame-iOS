//
//  LongElementQuest.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 25/02/25.
//

import Foundation
import osmparser
import SwiftUI
import CoreLocation

class LongElementQuest: QuestBase, Quest {
    
    var icon: UIImage {
        if let iconName = elementTypeIcon,
           let image = UIImage(named: iconName) {
            return image
        } else {
            let lowercasedElementType = elementType.lowercased()
            
            switch lowercasedElementType {
            case "sidewalks":
                return UIImage(named: "sidewalk_surface.pdf")!
            case "crossings":
                return UIImage(named: "pedestrian")!
            case "kerb":
                return UIImage(named: "kerb_type")!
            default:
                return UIImage(named: "other_element")!
            }
        }
    }

    
    var title: String = ""
    
    var filter: String {
        return QuestsRepository.shared.questQueryForElementType(elementType) ?? _internalQueryString!
    }
        
    var wikiLink: String = ""
    
    private(set) var elementType: String = ""
    
    private(set) var elementTypeIcon: String?
    
    
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
            let longQuestQuery = self._internalQueryString
            var filter = ""
            
            if let longQuestQuery = longQuestQuery {
                filter = longQuestQuery + " and !ext:gig_complete"
            } else {
                filter = " and !ext:gig_complete"
            }
            _internalExpression = try? filter.toElementFilterExpression()
            return _internalExpression
        }
    }
    
    var displayUnit: DisplayUnit {
        let uid = String(self.relationData?.id ?? 0)
        return DisplayUnit(title: self.title, description: "", id: "\(uid)-\(questId)",parent: self,sheetSize: .LONGFORM)
    }
    
    var questAnswersSelected: (([String:String]) -> Void)? = nil
    
    var annotationCoordinate: CLLocationCoordinate2D? {
          didSet {
              updateForm()
          }
      }
    
    private func updateForm() {
          self.internalForm = LongForm(
            elementName: elementType, questID: questId, query: _internalQueryString, action: { [self] tags in
                self.questAnswersSelected?(tags)
            }, coordinate: annotationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
          )
      }
    
    init(questId: String, questQuery:String, elementType: String, elementTypeIcon: String?) {
        super.init()
        self._internalQueryString = questQuery
        self.elementType = elementType
        self.elementTypeIcon = elementTypeIcon
        self.internalForm = LongForm(elementName: elementType, questID: questId,query: questQuery, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        })
    }
    
    override init() {
        super.init()
        
        self.internalForm = LongForm(elementName: elementType, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        })
    }
    
    var relationData: Element? = nil
    
    func onAnswer(answer: [String : String]) {
        if let rData = self.relationData  {
            self.updateTags(id: rData.id, tags: answer, type: rData.type)
        }
    }
        
    var questId: String {
        return String(self.relationData?.id ?? 0)
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let questId = String(element.id)
        let quest = LongElementQuest(questId: questId, questQuery: _internalQueryString!, elementType: elementType, elementTypeIcon: elementTypeIcon)
        quest.relationData = element
        return quest
    }
}
