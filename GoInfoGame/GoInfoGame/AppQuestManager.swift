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
import RealmSwift


// Class that handles data handling and display of annotations
class AppQuestManager {
    
//    let opManager = OverpassRequestManager()
    
    let dbInstance = DatabaseConnector.shared
    
    static let shared = AppQuestManager()
    private init() {}
    
    private let seedBox = BBox(minLat: 47.70312160869372, maxLat: 47.718964653825054, minLon: -122.20866792353317, maxLon: -122.18570621653987)
    
    func getUpdatedQuest(elementId: String) -> DisplayUnitWithCoordinate? {
        let nodesFromStorage = dbInstance.getNodes().filter { n in
            n.tags.count != 0
        }
        let waysFromStorage = dbInstance.getWays().filter{w in w.tags.count != 0 }
        let theWay = waysFromStorage.first(where: {$0.id == Int(elementId)})
        let theNode = nodesFromStorage.first(where: {$0.id == Int(elementId)})
        let allQuests = QuestsRepository.shared.applicableQuests
        // theElement if not equal to nil
        if (theNode != nil) {
            let nodeElement = theNode?.asNode()
            for quest in allQuests {
                    if quest.quest.filter.isEmpty {continue} // Ignore quest
                    if quest.quest.isApplicable(element: nodeElement!){
                        // Create a duplicate of the quest
                        // Create a display Unit
                        let duplicateQuest = quest.quest.copyWithElement(element: nodeElement!)
                        let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: nodeElement!.position.latitude, longitude: nodeElement!.position.longitude), id: nodeElement!.id, isHidden: false)
                        return unit
                    }
            }
            
        }
        else if (theWay != nil){
            let wayElement = theWay?.asWay()
            for quest in allQuests {
                    if quest.quest.filter.isEmpty {continue} // Ignore quest
                    if quest.quest.isApplicable(element: wayElement!){
                        // Create a duplicate of the quest
                        // Need to add another here.
                        let duplicateQuest = quest.quest.copyWithElement(element: wayElement!)
                        let position  = dbInstance.getCenterForWay(id: String(wayElement!.id)) ?? CLLocationCoordinate2D()
                        let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: wayElement!.id, isHidden: false)
                    return unit
                    }
            }
            
        }
        return nil
    }

    // Fetches all the available quests from Database
    func fetchQuestsFromDB() ->  [DisplayUnitWithCoordinate] {
            
        let allOriginalNodes = dbInstance.getNodes().filter { $0.isOriginal && $0.tags.count != 0 }
        
    
        let nodesFromStorage: [StoredNode] = allOriginalNodes.compactMap { original in
            original.tags["ext:gig_complete"] == "yes" ? nil : original
        }
             
        let allOriginalWays = dbInstance.getWays().filter {
            $0.isOriginal && $0.tags.count != 0
        }

        let waysFromStorage: [StoredWay] = allOriginalWays.compactMap { original in
            original.tags["ext:gig_complete"] == "yes" ? nil : original
        }
    
        
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
                    if quest.quest.filter.isEmpty {continue} // Ignore quest
                    if quest.quest.isApplicable(element: node){
                        // Create a duplicate of the quest
                        // Create a display Unit
                        let duplicateQuest = quest.quest.copyWithElement(element: node)
                        let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: node.position.latitude, longitude: node.position.longitude), id: node.id, isHidden: false)
                        displayUnits.append(unit)
                        nodeQuests.append(duplicateQuest)
                        break
                    }
                
            }
        }
        for way in wayElements{
            for quest in allQuests {
                    if quest.quest.filter.isEmpty {continue} // Ignore quest
                    if quest.quest.isApplicable(element: way){
                        // Create a duplicate of the quest
                        // Need to add another here.
                        let duplicateQuest = quest.quest.copyWithElement(element: way)
                        let position  = dbInstance.getCenterForWay(id: String(way.id)) ?? CLLocationCoordinate2D()
                        let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: way.id, isHidden: false)
                        displayUnits.append(unit)
                        wayQuests.append(duplicateQuest)
                        break
                    }
            }
        }
        print("Sending back items")
        print(allQuests)
                
        
        // get hidden ids from hiddenElements
        let hiddenIds = HiddenQuestManager.shared.hiddenQuests.map { $0.id }
        let unitsToBeDisplayed = displayUnits.filter { !hiddenIds.contains($0.id) }
        return unitsToBeDisplayed
    }
    
    // FIXME: Make this function better
    // Fetches the quest for a specific changeset based on the element
    // If there is no need to show the element after undo, it will return nil
    func fetchQuestForChangeset(storedChangesetId: String) -> DisplayUnitWithCoordinate? {
        if let changeset = dbInstance.getChangeset(for: storedChangesetId) {
            // Get the element based on the changeset
            let storedElementId = changeset.elementId
            let storedElementType = changeset.elementType
            var parserElement: osmparser.Element? = nil
            if (storedElementType == .node) {
               let storedElement = dbInstance.getNode(id: storedElementId, version: .original)
                parserElement = storedElement?.asNode()
            }
            else if (storedElementType == .way){
               let storedElement = dbInstance.getWay(id: storedElementId, version: .original)
                parserElement = storedElement?.asWay()
            }
            if let parserElement = parserElement {
                let allQuests = QuestsRepository.shared.applicableQuests
                for quest in allQuests {
                    if quest.quest.filter.isEmpty {
                        continue
                    }
                    if quest.quest.isApplicable(element: parserElement){
                        let duplicateQuest = quest.quest.copyWithElement(element: parserElement)
                        // Assign stuff based on the type of element
                        if parserElement.type == .node {
                            if let nodObj = parserElement as? osmparser.Node {
                                let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: nodObj.position.latitude, longitude: nodObj.position.longitude), id: nodObj.id, isHidden: false)
                                return unit
                            }
                          
                        }
                        else if parserElement.type == .way {
                            let position  = dbInstance.getCenterForWay(id: String(parserElement.id)) ?? CLLocationCoordinate2D()
                            let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: parserElement.id, isHidden: false)
                            return unit
                        }
                        
                    }
                }
                
            }
            
           
            
        }
        return nil
    }
}


