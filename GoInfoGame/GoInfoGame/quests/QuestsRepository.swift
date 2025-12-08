//
//  QuestsRepository.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import MapKit
import osmparser
import Combine

import Foundation

import ClusterMap

struct ApplicableQuest {
    var quest: any Quest
    var questId: String
    var isDefault: Bool {
        didSet {
            UserDefaults.standard.set(isDefault, forKey: "\(questId)_isDefault")
        }
    }
    
    init(quest:any Quest, questId: String) {
        self.quest = quest
        self.questId = questId
        self.isDefault = UserDefaults.standard.object(forKey: "\(questId)_isDefault") as? Bool ?? true
    }
    
    mutating func toggleIsDefault() {
        isDefault.toggle()
        let questDef =  "\(questId)_isDefault"
        print(questDef)
        UserDefaults.standard.set(isDefault, forKey: "\(questId)_isDefault")
    }
}

// singleton class that has all the quest type instances
class QuestsRepository: ObservableObject {
    static let shared = QuestsRepository()
    private init() {
        print("QUEST REPO INITIALISED")
    }
        
    @Published var allQuests: [ApplicableQuest] = []
       
       var applicableQuests: [ApplicableQuest] {
           allQuests.filter { $0.isDefault }
       }
    
    @Published var longQuestModels: [LongFormElement] = []
    
    var displayQuests: [DisplayUnit] {
        self.applicableQuests.map { q in
            q.quest.displayUnit
        }
    }
    var displayCoordQuests: [DisplayUnitWithCoordinate] {
            self.applicableQuests.map { quest in
                let randomCoordinate = generateRandomCoordinates()
                return DisplayUnitWithCoordinate(
                    displayUnit: quest.quest.displayUnit,
                    coordinateInfo: randomCoordinate,
                    id:Int64.random(in: 2...90000), isHidden: false
                )
            }
    }
    private func generateRandomCoordinates() -> CLLocationCoordinate2D {
            let seattleCoordinate = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
            let randomLat = seattleCoordinate.latitude + Double.random(in: -0.1...0.1)
            let randomLon = seattleCoordinate.longitude + Double.random(in: -0.1...0.1)
            
            return CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon)
        }
    
    func loadLongQuests(from fileName: String) {
            do {
                if let loadedQuests = try FileStorageManager.shared.load(from: fileName) {
                    self.longQuestModels = loadedQuests
                } else {
                    print("File not found")
                }
            } catch {
                print("Failed to load file: \(error)")
            }
        }
    
    
}
// Probably move somewhere else
class DisplayUnitAnnotation: NSObject, MKAnnotation, CoordinateIdentifiable, Identifiable {
    var displayUnit: DisplayUnit?
    var coordinate: CLLocationCoordinate2D
    let id: String
    var title: String? {
        return displayUnit?.title
    }

    var subtitle: String? {
        return displayUnit?.description
    }

    init(id: String, coordinate: CLLocationCoordinate2D)  {
        self.id = id
        self.coordinate = coordinate
    }
    
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? DisplayUnitAnnotation else  {return false}
        return self.id == object.id
//        guard let quest = self.displayUnit.parent as? (any Quest) else {return false}
//        guard let rData = quest.relationData, let oDat = object.displayUnit.parent?.relationData as? Element else {return false}
//        
//        return self.coordinate == object.coordinate && self.title == object.title && rData.id == oDat.id
    }
    
    override var hash: Int {
           return id.hashValue
       }
}

struct DisplayUnitWithCoordinate: Identifiable, Equatable {
    let displayUnit: DisplayUnit
    let coordinateInfo: CLLocationCoordinate2D
    let id: Int64
    var isHidden: Bool
    let location: CLLocation
    init(displayUnit: DisplayUnit, coordinateInfo: CLLocationCoordinate2D, id: Int64, isHidden: Bool) {
        self.displayUnit = displayUnit
        self.coordinateInfo = coordinateInfo
        self.id = id
        self.isHidden = isHidden
        self.location = CLLocation(latitude: coordinateInfo.latitude, longitude: coordinateInfo.longitude)
    }

    var annotation: DisplayUnitAnnotation {
        let annotation = DisplayUnitAnnotation(id: displayUnit.id, coordinate: coordinateInfo)
        annotation.displayUnit = displayUnit
        return annotation
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id &&
        lhs.isHidden == rhs.isHidden &&
        lhs.coordinateInfo.latitude == rhs.coordinateInfo.latitude &&
        lhs.coordinateInfo.longitude == rhs.coordinateInfo.longitude
    }
}

extension QuestsRepository {
    func questQueryForElementType(_ elementType: String) -> String? {
        return longQuestModels.first(where: { $0.elementType.lowercased() == elementType.lowercased() })?.questQuery
    }
    
    func questElementForQuery(_ query: String) -> LongFormElement? {
        return longQuestModels.first(where: {$0.questQuery == query})
    }
}

class CluserableDisplayUnitAnnotation: DisplayUnitAnnotation  {
    var memberAnnotations = [MKAnnotation]()
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CluserableDisplayUnitAnnotation else { return false }

        if self === object {
            return true
        }

        if coordinate != object.coordinate {
            return false
        }

        if memberAnnotations.count != object.memberAnnotations.count {
            return false
        }

        return memberAnnotations.map(\.coordinate) == object.memberAnnotations.map(\.coordinate)
    }
    
}
