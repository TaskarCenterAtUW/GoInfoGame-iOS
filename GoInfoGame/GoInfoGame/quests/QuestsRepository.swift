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

import Foundation

struct ApplicableQuest {
    var quest: any Quest
    var questId: String
    var isDefault: Bool {
        didSet {
            UserDefaults.standard.set(isDefault, forKey: "\(quest)_isDefault")
        }
    }
    
    init(quest:any Quest, questId: String) {
        self.quest = quest
        self.questId = questId
        self.isDefault = UserDefaults.standard.object(forKey: "\(quest)_isDefault") as? Bool ?? true
    }
    
    mutating func toggleIsDefault() {
        isDefault.toggle()
        let questDef =  "\(quest)_isDefault"
        print(questDef)
        UserDefaults.standard.set(isDefault, forKey: "\(quest)_isDefault")
    }
}

// singleton class that has all the quest type instances
class QuestsRepository: ObservableObject {
    static let shared = QuestsRepository()
    private init() {
        print("QUEST REPO INITIALISED")
    }
    
    var sideWalkLongQuestModel: LongFormModel? {
          return longQuestModels.first(where: { $0.elementType.lowercased() == "sidewalks" })
      }
    
    var kerbLongQuestModel: LongFormModel? {
          return longQuestModels.first(where: { $0.elementType.lowercased() == "kerb" })
      }
    
    var crossingsLongQuestModel: LongFormModel? {
          return longQuestModels.first(where: { $0.elementType.lowercased() == "crossings" })
      }
    
    @Published var applicableQuests: [ApplicableQuest] = [
//       ApplicableQuest(quest: LongSidewalkQuest(), questId: "1"),
        ApplicableQuest(quest: LongKerbQuest(), questId: "1"),
       ApplicableQuest(quest: LongCrossingQuest(), questId: "2")
       

        
//        ApplicableQuest(quest: CrossingType(), questId: "1"),
//        ApplicableQuest(quest: CrossingIsland(), questId: "8"),
//        ApplicableQuest(quest: CrossMarking(), questId: "10"),
////        ApplicableQuest(quest: SidewalkSurface(), questId: "31"),
//        ApplicableQuest(quest: StairFlights(), questId: "4"),
//        ApplicableQuest(quest: TactilePavingSteps(), questId: "27"),
////        ApplicableQuest(quest: SideWalkWidth(), questId: "3"),
//        ApplicableQuest(quest: StepsIncline(), questId: "32"),
//        ApplicableQuest(quest: TactilePavingCrosswalk(), questId: "14"),
//        ApplicableQuest(quest: CrossingKerbHeight(), questId: "9"),
//        ApplicableQuest(quest: KerbHeight(), questId: "19")
    ]
    
//    @Published var applicableQuests: [ApplicableQuest] = [
//        ApplicableQuest(quest: LongSidewalkQuest(), questId: "1"),
//    ]
//    

//        HandRail(),
//        StepsRamp(),
//        StairNumber(),
//        WayLit(),
//        BusStopLit(),
//        SideWalkValidation(),
//        TactilePavingKerb(),
    
    @Published var longQuestModels: [LongFormModel] = []
    
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
                    id:Int64.random(in: 2...90000)
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
class DisplayUnitAnnotation: NSObject, MKAnnotation {
    let displayUnit: DisplayUnit
    let coordinate: CLLocationCoordinate2D

    var title: String? {
        return displayUnit.title
    }

    var subtitle: String? {
        return displayUnit.description
    }

    init(displayUnit: DisplayUnit, coordinate: CLLocationCoordinate2D) {
        self.displayUnit = displayUnit
        self.coordinate = coordinate
    }
    
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? DisplayUnitAnnotation else  {return false}
        return self.displayUnit.id == object.displayUnit.id
//        guard let quest = self.displayUnit.parent as? (any Quest) else {return false}
//        guard let rData = quest.relationData, let oDat = object.displayUnit.parent?.relationData as? Element else {return false}
//        
//        return self.coordinate == object.coordinate && self.title == object.title && rData.id == oDat.id
    }
    
    override var hash: Int {
           return displayUnit.id.hashValue
       }
}

struct DisplayUnitWithCoordinate: Identifiable {
    let displayUnit: DisplayUnit
    let coordinateInfo: CLLocationCoordinate2D
    let id: Int64

    var annotation: DisplayUnitAnnotation {
        return DisplayUnitAnnotation(displayUnit: displayUnit, coordinate: coordinateInfo)
    }
}
