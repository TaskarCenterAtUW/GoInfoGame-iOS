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
        let nodesFromStorage = dbInstance.getNodes(NSPredicate(format: "tags.@count != 0"))
        let waysFromStorage = dbInstance.getWays(NSPredicate(format: "tags.@count != 0"))
        let theWay = waysFromStorage.first(where: {$0.id == Int64(elementId)})
        let theNode = nodesFromStorage.first(where: {$0.id == Int64(elementId)})
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
                    let position  = dbInstance.getCenterForWay(id: wayElement!.id) ?? CLLocationCoordinate2D()
                    let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: wayElement!.id, isHidden: false)
                    return unit
                }
            }
            
        }
        return nil
    }
    
    // Helper function to check if a quest contains AutoCapture type questions
    func hasAutoCaptureQuest(quest: ApplicableQuest) -> Bool {
        // Try to access the quest's elements and check if any have AutoCapture questType
        // This is a generic check that works with different quest types
        
        // Get the display unit to access underlying data
        let displayUnit = quest.quest.displayUnit
        
        // Check if the display unit's parent has quests
        if let longFormElement = displayUnit.parent as? LongFormElement {
            // Check all quests in this element
            for questItem in longFormElement.quests {
                // Check if questType is AutoCapture
                if String(describing: questItem.questType).lowercased().contains("autocapture") {
                    return true
                }
            }
        }
        
        // Fallback: Check the description or name
        let questDescription = String(describing: quest.quest).lowercased()
        if questDescription.contains("autocapture") {
            return true
        }
        
        return false
    }
    
    // Fetches all the available quests from Database
    func fetchQuestsFromDB() ->  [DisplayUnitWithCoordinate] {
        // Filter logic:
        // 1. Show quests where ext:gig_complete != 'yes' (not completed)
        // 2. If ext:gig_complete == 'yes' (completed):
        //    - On LiDAR devices: show only if ext:autoCapture:ignored != 'yes' (to allow re-capture)
        //    - On non-LiDAR devices: hide (already completed)
        
        let deviceSupportsLiDAR = LiDARDetection.shared.isLiDARSupported()
        
        // Build filter predicate based on device capability
        let nodePredicate: NSPredicate
        let wayPredicate: NSPredicate
        
        if deviceSupportsLiDAR {
            // On LiDAR devices: show incomplete quests + completed quests that were ignored (autoCapture)
            nodePredicate = NSPredicate(format: """
                tags.@count != 0 AND 
                (tags['ext:gig_complete'] != 'yes' OR 
                 (tags['ext:gig_complete'] == 'yes' AND tags['ext:autoCapture:ignored'] == nil))
                """)
            wayPredicate = NSPredicate(format: """
                tags.@count != 0 AND
                polyline.@count > 0 AND
                (tags['ext:gig_complete'] != 'yes' OR 
                 (tags['ext:gig_complete'] == 'yes' AND tags['ext:autoCapture:ignored'] == nil))
                """)
        } else {
            // On non-LiDAR devices: show only incomplete quests
            nodePredicate = NSPredicate(format: """
                tags.@count != 0 AND 
                tags['ext:gig_complete'] != 'yes'
                """)
            wayPredicate = NSPredicate(format: """
                tags.@count != 0 AND
                polyline.@count > 0 AND
                tags['ext:gig_complete'] != 'yes'
                """)
        }
        
        let nodesFromStorage = dbInstance.getNodes(nodePredicate)
        let yetToSyncNodeIDs = Set(dbInstance.getChangesets(synced: false, element: .node).compactMap{ Int64($0.elementId) })
        
        let waysFromStorage = dbInstance.getWays(wayPredicate)
        let yetToSyncWayIDs = Set(dbInstance.getChangesets(synced: false, element: .way).compactMap{ Int64($0.elementId) })
        
        debugPrint("converting to nods: start \(Date())")
        let nodeElements: [Node] = nodesFromStorage.compactMap { node in
            if yetToSyncNodeIDs.contains(node.id) {
                return nil
            }
            return node.asNode()
        }
        
        debugPrint("converting to nods: end \(Date())")
        debugPrint("converting to way: start \(Date())")
        let wayElements: [Way] = waysFromStorage.compactMap{ way in
            if yetToSyncWayIDs.contains(way.id) {
                return nil
            }
            return way.asWay()
        }
        
        debugPrint("converting to way: end \(Date())")
        // Get the quests for nodes
        var nodeQuests: [any Quest] = []
        var wayQuests: [any Quest] = []
        let allQuests = QuestsRepository.shared.applicableQuests
        var displayUnits : [DisplayUnitWithCoordinate] = []
        
        debugPrint("process nodes: start: \(Date())")
        // Get the quests for ways
        for node in nodeElements {
            // Get the quests and try to iterate
            for quest in allQuests {
                if quest.quest.filter.isEmpty {continue} // Ignore quest
                if quest.quest.isApplicable(element: node){
                    // identify is it list to show only LiDAR quest?
                    var showOnlyLiDARQuest: Bool = false
                    if deviceSupportsLiDAR &&
                        node.tags["ext:gig_complete"] == "yes" &&
                        node.tags["ext:autoCapture:ignored"] == nil {
                        // This quest is completed but was ignored for auto-capture, so we show it for re-capture
                        showOnlyLiDARQuest = true
                    }
                    // Create a duplicate of the quest
                    // Create a display Unit
                    let duplicateQuest = quest.quest.copyWithElement(element: node)
                    let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: node.position.latitude, longitude: node.position.longitude), id: node.id, isHidden: false, showOnlyLiDARQuest: showOnlyLiDARQuest)
                    displayUnits.append(unit)
                    nodeQuests.append(duplicateQuest)
                    break
                }
                
            }
        }
        debugPrint("process nodes: end: \(Date())")
        debugPrint("process ways: start: \(Date())")
        for way in wayElements{
            for quest in allQuests {
                if quest.quest.filter.isEmpty {continue} // Ignore quest
                if quest.quest.isApplicable(element: way){
                    // identify is it list to show only LiDAR quest?
                    var showOnlyLiDARQuest: Bool = false
                    if deviceSupportsLiDAR &&
                        way.tags["ext:gig_complete"] == "yes" &&
                        way.tags["ext:autoCapture:ignored"] == nil {
                        // This quest is completed but was ignored for auto-capture, so we show it for re-capture
                        showOnlyLiDARQuest = true
                    }
                    
                    // Create a duplicate of the quest
                    // Need to add another here.
                    let duplicateQuest = quest.quest.copyWithElement(element: way)
                    let position  = dbInstance.getCenterForWay(id: way.id) ?? CLLocationCoordinate2D()
                    let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: way.id, isHidden: false, showOnlyLiDARQuest: showOnlyLiDARQuest)
                    displayUnits.append(unit)
                    wayQuests.append(duplicateQuest)
                    break
                }
            }
        }
        debugPrint("process ways: end: \(Date())")
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
               let storedElement = dbInstance.getNode(id: storedElementId)
                parserElement = storedElement?.asNode()
            }
            else if (storedElementType == .way){
               let storedElement = dbInstance.getWay(id: storedElementId)
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
                            let position  = dbInstance.getCenterForWay(id: parserElement.id) ?? CLLocationCoordinate2D()
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


