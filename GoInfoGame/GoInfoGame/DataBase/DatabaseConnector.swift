//
//  DatabaseConnector.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 25/11/23.
//

import Foundation
import RealmSwift
import SwiftOverpassAPI
import MapKit

class DatabaseConnector {
    static let shared = DatabaseConnector()
    
    private let realm: Realm
    
    private init() {
        // Initialize Realm instance
        realm = try! Realm()
        if let realmURL = realm.configuration.fileURL {
            print("Realm Database Path: \(realmURL.path)")
        }
    }
    
    func saveElements(_ elements: [OPElement]) {
        // Save the elements appropriately
        // Get the ways and nodes out
        let nodes = elements.filter({$0 is OPNode}).filter({!$0.tags.isEmpty})
        let ways = elements.filter({$0 is OPWay}).filter({!$0.tags.isEmpty})
        do {
            try realm.write {
                for node in nodes {
                    let storedElement = StoredNode()
                    storedElement.id = node.id
                    for tag in node.tags {
                        if (!tag.key.contains(".")) { // Do a utility function
                            storedElement.tags.setValue(tag.value, forKey: tag.key)
                        }
                    }
                    if let meta = node.meta {
                        storedElement.version = meta.version
                        storedElement.timestamp = meta.timestamp
                    }
                    if let asNode = node as? OPNode{
                        switch asNode.geometry {
                        case .center(let coordinate):
                            storedElement.point = coordinate
                        default:
                            continue
                        }
                    }
                    realm.add(storedElement, update: .modified)
                }
                // Store the ways
                for way in ways {
                    let storedWay = StoredWay()
                    storedWay.id = way.id
                    for tag in way.tags {
                        if(!tag.key.contains(".")){ // Do a utility function
                            storedWay.tags.setValue(tag.value, forKey: tag.key)
                        }
                    }
                    
                    
                    if let meta = way.meta {
                        storedWay.version = meta.version
                        storedWay.timestamp = meta.timestamp
                    }
                    if let asWay = way as? OPWay {
                        storedWay.nodes.append(objectsIn: asWay.nodes.map({Int64($0)}))
                        // Store the coordinates
                        switch asWay.geometry {
                        case .polygon(let coordinates):
                            storedWay.polyline.append(objectsIn: coordinates)
                        default:
                            print("Ignoring geometry")
                        }
                    }
                    realm.add(storedWay, update: .modified)
                }
            }
        } catch {
            print("Elements to be skipped or something happened")
        }
    }
    
    func saveElements(_ elements: [OPWay]) {
        do {
            try realm.write {
                for element in elements {
                    let realmElement = RealmOPElement()
                    realmElement.id = element.id
                    realmElement.isInteresting = element.isInteresting
                    realmElement.isSkippable = element.isSkippable
                    
                    let realmTags = element.tags.map { tag in
                        let realmTag = RealmOPElementTag()
                        realmTag.key = tag.key
                        realmTag.value = tag.value
                        return realmTag
                    }
                    realmElement.tags.append(objectsIn: realmTags)
                    
                    if let meta = element.meta {
                        let realmMeta = RealmOPMeta()
                        realmMeta.version = meta.version
                        realmMeta.timestamp = meta.timestamp
                        realmMeta.changeset = meta.changeset
                        realmMeta.userId = meta.userId
                        realmMeta.username = meta.username
                        realmElement.meta = realmMeta
                    } else {
                        realmElement.meta = RealmOPMeta()
                    }
                    
                    if !element.nodes.isEmpty {
                        realmElement.nodes.append(objectsIn: element.nodes)
                    }
                    let geometry =  RealmOPGeometry(geometry: element.geometry)
                    realmElement.geometry.append(geometry)
                    realm.add(realmElement, update: .modified)
                }
                
                
            }
        } catch {
            print("Error saving elements to Realm: \(error)")
        }
    }
    
    func getNodes() -> Results<StoredNode> {
        return realm.objects(StoredNode.self)
    }
    
    func getWays() -> Results<StoredWay> {
        return realm.objects(StoredWay.self)
    }
    
    func getCenterForWay(id: String) -> CLLocationCoordinate2D? {
        // Get all the objects for the way
        guard let way = realm.object(ofType: StoredWay.self, forPrimaryKey: Int(id))  else {
            return nil
        }
        let nodeIds = way.nodes
        // Get the nodes for each
        var nodeCoords: [CLLocationCoordinate2D] = []
        for nodeId in nodeIds {
            if let node = realm.object(ofType: StoredNode.self , forPrimaryKey: Int(nodeId)){
                nodeCoords.append(node.point)
            }
        }
        if (!nodeCoords.isEmpty) {
            let latitudeSum = nodeCoords.map({$0.latitude}).reduce(0, +)  / Double(nodeCoords.count)
            let longitudeSum = nodeCoords.map({$0.longitude}).reduce(0, +)  / Double(nodeCoords.count)
            
            return CLLocationCoordinate2D(latitude: latitudeSum, longitude: longitudeSum)
        }
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        
    }
    
    func getNode(id:String) -> StoredNode? {
        return realm.object(ofType: StoredNode.self, forPrimaryKey: Int(id))
    }
    
    func getWay(id: String) -> StoredWay? {
        return realm.object(ofType: StoredWay.self, forPrimaryKey: Int(id))
    }
    
    func addNodeTags(id: String, tags:[String: String]) -> StoredNode? {
        guard let theNode = getNode(id: id) else { return nil }
        do {
            try realm.write {
                tags.forEach { (key: String, value: String) in
                    theNode.tags.setValue(value, forKey: key)
                }
            }
        }
        catch {
            print("Error while writing tags")
        }
       
        //realm.add(theNode, update: .all) // Test this
        return theNode
    }
    
    
    func addWayTags(id: String, tags:[String:String]) -> StoredWay? {
        guard let theWay = getWay(id: id) else { return nil }
        
        tags.forEach { (key: String, value: String) in
            theWay.tags.setValue(value, forKey: key)
        }
        
        realm.add(theWay, update: .all) // Test this
        return theWay
    }
    
    func createChangeset(id:String, type: StoredElementEnum, tags:[String:String]) -> StoredChangeset? {
        let storedChangeset = StoredChangeset()
        storedChangeset.elementId = id
        storedChangeset.elementType = type
        storedChangeset.timestamp =  String(Date().timeIntervalSince1970)
        for tag in tags {
            storedChangeset.tags.setValue(tag.value, forKey: tag.key)
        }
        do {
            try realm.write {
                realm.add(storedChangeset)
            }
        } catch {
            print("Error while writing the changeset")
            return nil
        }
        return storedChangeset
    }
    
    func getChangesets(synced: Bool = false) -> Results<StoredChangeset> {
        
        if (synced == true){
            return  realm.objects(StoredChangeset.self).where({$0.changesetId != -1 })
        }
        return realm.objects(StoredChangeset.self).where({$0.changesetId == -1 })
    }
    
    func assignChangesetId(obj:String, changesetId: Int) -> StoredChangeset? {
        guard let changeset = realm.object(ofType: StoredChangeset.self, forPrimaryKey: obj) else {
            return nil
        }
        do {
            try realm.write {
                changeset.changesetId = changesetId // Not sure if this changes the value
            }
            return changeset
        } catch (let error){
            return nil
        }
    }
}
