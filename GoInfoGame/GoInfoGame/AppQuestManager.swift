//
//  AppQuestManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/25/24.
//

import Foundation
import SwiftOverpassAPI
import osmparser
import MapKit


// Class that handles data handling and display of annotations
class AppQuestManager {
    
    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    
    
    static let shared = AppQuestManager()
    private init() {}
    
    private let seedBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
    
    func addSeedData() {
        fetchData(fromBBOx: seedBox )
    }
    
    // Fetch the quests for a bounding box
    func fetchData(fromBBOx bbox: BBox){
        // Get the data from bbox
        opManager.fetchElements(fromBBox: bbox) { fetchedElements in
            // Get the count of nodes and ways
            let allValues = fetchedElements.values
            let allElements = allValues.filter({!$0.tags.isEmpty})
            print("Saving tags")
            self.dbInstance.saveElements(allElements) // Save all where there are tags
        }
    }
    
    
    
    // Fetches all the available quests from Database
    func fetchQuestsFromDB() ->  [DisplayUnitWithCoordinate] {
        let nodesFromStorage = dbInstance.getNodes()
        let waysFromStorage = dbInstance.getWays()
        let nodeElements = nodesFromStorage.map({$0.asNode()})
        let wayElements = waysFromStorage.map({$0.asWay()})
        
        // Get the quests for nodes
        var nodeQuests: [any Quest] = []
        var wayQuests: [any Quest] = []
        let allQuests = QuestsRepository.shared.applicableQuests
        var displayUnits : [DisplayUnitWithCoordinate] = []
        
        // Get the quests for ways
        for node in nodeElements {
            // Get the quests and try to iterate
            for quest in allQuests {
                if quest.filter.isEmpty {continue} // Ignore quest
                if quest.isApplicable(element: node){
                    // Create a duplicate of the quest
                    // Create a display Unit
                    let unit = DisplayUnitWithCoordinate(displayUnit: quest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: node.position.latitude, longitude: node.position.longitude), id: node.id)
                    displayUnits.append(unit)
                    nodeQuests.append(quest)
                    break
                }
            }
        }
        for way in wayElements{
            for quest in allQuests {
                if quest.filter.isEmpty {continue} // Ignore quest
                if quest.isApplicable(element: way){
                    // Create a duplicate of the quest
                    // Need to add another here.
                    let position  = dbInstance.getCenterForWay(id: String(way.id)) ?? CLLocationCoordinate2D()
                    let unit = DisplayUnitWithCoordinate(displayUnit: quest.displayUnit, coordinateInfo: position, id: way.id)
                    displayUnits.append(unit)
                    
                    wayQuests.append(quest)
                    break
                }
            }
        }
        print("Sending back items")
        return displayUnits
    }
}
