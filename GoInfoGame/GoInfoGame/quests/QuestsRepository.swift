//
//  QuestsRepository.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/17/24.
//

import Foundation
import MapKit
import osmparser

// singleton class that has all the quest type instances
class QuestsRepository {
    static let shared = QuestsRepository()
    private init() {}
    
    let applicableQuests: [ any Quest] = [
        
        CrossingType(),
        CrossingIsland(),
        CrossMarking(),
        SidewalkSurface(),
        StairFlights(),
        TactilePavingSteps(),
        SideWalkWidth(),
        StepsIncline(),
        TactilePavingCrosswalk(),
        CrossingKerbHeight(),
        KerbHeight()


        
//        HandRail(),
//        StepsRamp(),
//        StairNumber(),
//        WayLit(),
//        BusStopLit(),
//        SideWalkValidation(),
//        TactilePavingKerb(),
    ]
    
    var displayQuests: [DisplayUnit] {
        self.applicableQuests.map { q in
            q.displayUnit
        }
    }
    var displayCoordQuests: [DisplayUnitWithCoordinate] {
            self.applicableQuests.map { quest in
                let randomCoordinate = generateRandomCoordinates()
                return DisplayUnitWithCoordinate(
                    displayUnit: quest.displayUnit,
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
