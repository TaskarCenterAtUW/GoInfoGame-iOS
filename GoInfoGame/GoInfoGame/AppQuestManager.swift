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
        // Primary-key lookups — scanning every stored node/way here ran on the main
        // thread after each answer sync and grew with the workspace size.
        let id = Int(elementId) ?? -1
        let theNode = dbInstance.getNode(id: id).flatMap { $0.tags.count == 0 ? nil : $0 }
        let theWay = dbInstance.getWay(id: id).flatMap { $0.tags.count == 0 ? nil : $0 }
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
    
    // Fetches all the available quests from Database
    func fetchQuestsFromDB() ->  [DisplayUnitWithCoordinate] {

        // Completeness is no longer determined by ext:gig_complete — the long form's
        // question set is configurable from the web and can change over time, so a
        // stamped tag from a past submission can't be trusted as a query-level
        // shortcut. The real check (LongElementQuest.isApplicable, via
        // LongFormElement.isFullyAnswered) always runs against the element's actual
        // current tags below.
        let nodePredicateFormat = "tags.@count != 0"
        let wayPredicateFormat = "tags.@count != 0 AND polyline.@count > 0"

        let nodesFromStorage = dbInstance.getNodes(NSPredicate(format: nodePredicateFormat))
        let yetToSyncNodeIDs = Set(dbInstance.getChangesets(synced: false, element: .node).compactMap{ Int64($0.elementId) })

        let waysFromStorage = dbInstance.getWays(NSPredicate(format: wayPredicateFormat))
        let yetToSyncWayIDs = Set(dbInstance.getChangesets(synced: false, element: .way).compactMap{ Int64($0.elementId) })
        
        let allQuests = QuestsRepository.shared.applicableQuests
        let hiddenIds = Set(HiddenQuestManager.shared.hiddenQuests.map { $0.id })
        var displayUnits : [DisplayUnitWithCoordinate] = []

        // Each element is converted, matched and released one at a time (inside its own
        // autorelease pool, which also drains Realm's accessor objects) instead of
        // converting every stored element up front — with tens of thousands of
        // elements, holding all the intermediate Node/Way objects at once alongside the
        // new quest copies roughly doubled the peak memory of every reload.
        debugPrint("process nodes: start: \(Date())")
        for storedNode in nodesFromStorage {
            if yetToSyncNodeIDs.contains(storedNode.id) || hiddenIds.contains(storedNode.id) { continue }
            autoreleasepool {
                let node = storedNode.asNode()
                guard let quest = firstApplicableQuest(in: allQuests, for: node) else { return }
                let duplicateQuest = quest.copyWithElement(element: node)
                let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo:  CLLocationCoordinate2D(latitude: node.position.latitude, longitude: node.position.longitude), id: node.id, isHidden: false)
                displayUnits.append(unit)
            }
        }
        debugPrint("process nodes: end: \(Date())")
        debugPrint("process ways: start: \(Date())")
        for storedWay in waysFromStorage {
            if yetToSyncWayIDs.contains(storedWay.id) || hiddenIds.contains(storedWay.id) { continue }
            autoreleasepool {
                let way = storedWay.asWay()
                guard let quest = firstApplicableQuest(in: allQuests, for: way) else { return }
                let duplicateQuest = quest.copyWithElement(element: way)
                let position = center(of: way) ?? dbInstance.getCenterForWay(id: way.id) ?? CLLocationCoordinate2D()
                let unit = DisplayUnitWithCoordinate(displayUnit: duplicateQuest.displayUnit, coordinateInfo: position, id: way.id, isHidden: false)
                displayUnits.append(unit)
            }
        }
        debugPrint("process ways: end: \(Date())")
        return displayUnits
    }

    private func firstApplicableQuest(in quests: [ApplicableQuest], for element: osmparser.Element) -> (any Quest)? {
        quests.first { !$0.quest.filter.isEmpty && $0.quest.isApplicable(element: element) }?.quest
    }
    
    /// Average of the way's stored polyline points — the same node coordinates
    /// `getCenterForWay` averages, without one Realm lookup per node.
    private func center(of way: Way) -> CLLocationCoordinate2D? {
        guard !way.polyline.isEmpty else { return nil }
        let count = Double(way.polyline.count)
        let lat = way.polyline.reduce(0) { $0 + $1.latitude } / count
        let lon = way.polyline.reduce(0) { $0 + $1.longitude } / count
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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


