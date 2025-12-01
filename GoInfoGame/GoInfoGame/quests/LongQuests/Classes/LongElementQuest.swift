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

struct LazyView<Content: View>: View, QuestForm {
    var action: (([String : String]) -> Void)?
    
    typealias AnswerClass = [String: String]
    
    let build: () -> Content

    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

class LongElementQuest: QuestBase, Quest {
    var polylines: [CLLocationCoordinate2D]?
    
    var id: Int64
    
    var type: osmparser.ElementType
    
    
    var iconName: String {
        if let iconName = elementTypeIcon {
            return iconName
        } else {
            let lowercasedElementType = elementType.lowercased()
            
            switch lowercasedElementType {
            case "sidewalks":
                return "sidewalk_surface"
            case "crossings":
                return "pedestrian"
            case "kerb":
                return "kerb_type"
            default:
                return "notes"
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
        let uid = String(self.id)
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
        id = -1
        type = .node
        super.init()
        self._internalQueryString = questQuery
        self.elementType = elementType
        self.elementTypeIcon = elementTypeIcon
        self.internalForm = LazyView(LongForm(elementName: elementType, questID: questId,query: questQuery, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        }))
    }
    
    override init() {
        id = -1
        type = .node
        super.init()
        
        self.internalForm = LongForm(elementName: elementType, action: { [self] tags in
//            self.onAnswer(answer: tags)
            self.questAnswersSelected?(tags)
        })
    }
    
    
    func onAnswer(answer: [String : String]) {
        self.updateTags(id: id, questType: elementType, tags: answer, type: type)
    }
        
    var questId: String {
        return String(self.id)
    }
    
    func copyWithElement(element: Element) -> any Quest {
        let questId = String(element.id)
        let quest = LongElementQuest(questId: questId, questQuery: _internalQueryString!, elementType: elementType, elementTypeIcon: elementTypeIcon)
        if let way = element as? Way {
            quest.polylines = way.polyline.compactMap { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
        }
        quest.id = element.id
        quest.type = element.type
        return quest
    }
}
