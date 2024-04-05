//
//  AppQuestManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/25/24.
//

import Foundation
//import SwiftOverpassAPI
import osmparser
import MapKit
import osmapi


// Class that handles data handling and display of annotations
class AppQuestManager {
    
//    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    let osmConnection = OSMConnection()
    
    static let shared = AppQuestManager()
    private init() {}
    
    private let seedBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
    
    func addSeedData() {
        fetchData(fromBBOx: seedBox ){}
    }
    
    // Fetch the quests for a bounding box
    func fetchData(fromBBOx bbox: BBox,completion: @escaping () -> Void){
        // Get the data from bbox
      //  let distance = 100
        //37.41465820658871,-122.0912196996173,37.42366839341129,-122.0799229003827
        
        osmConnection.fetchMapData(left:bbox.minLon , bottom:bbox.minLat , right:bbox.maxLon , top:bbox.maxLat ) { result in
            switch result {
            case .success(let mapData):
                let response = Array(mapData.values)
                let allValues = response
               // let allElements = allValues.filter({!$0.tags.isEmpty})
                print("Saving tags")
                DispatchQueue.main.async {
                    self.dbInstance.saveOSMElements(allValues) // Save all where there are tags
                    completion()
                }
            case .failure(let error):
                print("error")
            }
           
        }
//        opManager.fetchElements(fromBBox: bbox) { fetchedElements in
//            // Get the count of nodes and ways
//            let allValues = fetchedElements.values
//            let allElements = allValues.filter({!$0.tags.isEmpty})
//            print("Saving tags")
//            self.dbInstance.saveElements(allElements) // Save all where there are tags
//            completion()
//        }
    }
    
    
    
    
    // Fetches all the available quests from Database
    func fetchQuestsFromDB() ->  [DisplayUnitWithCoordinate] {
            
        let nodesFromStorage = dbInstance.getNodes().filter { n in
            n.tags.count != 0
        }
        let waysFromStorage = dbInstance.getWays().filter{w in w.tags.count != 0 }
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
                    let duplicateQuest = quest.copyWithElement(element: node)
                    let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: node.position.latitude, longitude: node.position.longitude), id: node.id)
                    displayUnits.append(unit)
                    nodeQuests.append(duplicateQuest)
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
                    let duplicateQuest = quest.copyWithElement(element: way)
                    let position  = dbInstance.getCenterForWay(id: String(way.id)) ?? CLLocationCoordinate2D()
                    let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: way.id)
                    displayUnits.append(unit)
//                    if(quest is SideWalkWidth){
//                        if let q = quest as? SideWalkWidth {
//                            q.assignAnsweringHandler()
//                        }
//                    }
                    wayQuests.append(duplicateQuest)
                    break
                }
            }
        }
        print("Sending back items")
        return displayUnits
    }
}
