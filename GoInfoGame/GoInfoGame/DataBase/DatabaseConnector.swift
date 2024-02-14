//
//  DatabaseConnector.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 25/11/23.
//

import Foundation
import RealmSwift
import MapKit
import osmapi

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
    
    /**
        Saves the OPElements into the database. This method does not remove the old data. However, it updates the
         data with same id
        @param elements  List of OPElement
     */
    func saveElements(_ elements: [OSMElement]) {
        // Save the elements appropriately
        // Get the ways and nodes out
        let nodes = elements.filter({$0 is OSMNode}).filter({!$0.tags.isEmpty})
        let ways = elements.filter({$0 is OSMWay}).filter({!$0.tags.isEmpty})
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        do {
            try realm.write {
                for node in nodes {
                    let storedElement = StoredNode()
                    storedElement.id = node.id
                    for tag in node.tags {
                        storedElement.tags.setValue(tag.value, forKey: tag.key)
                    }
//                    if let meta = node {
                        let timestampString = dateFormatter.string(from: node.timestamp)
                        storedElement.version = node.version
                        storedElement.timestamp = timestampString
//                    }
                    if let asNode = node as? OSMNode{
                        // coordinate from lat long
                        storedElement.point = CLLocationCoordinate2D(latitude: asNode.lat, longitude: asNode.lon)
//                        switch asNode.geometry {
//                        case .center(let coordinate):
//                            storedElement.point = coordinate
//                        default:
//                            continue
//                        }
                    }
                    realm.add(storedElement, update: .modified)
                }
                // Store the ways
                for way in ways {
                    let storedWay = StoredWay()
                    storedWay.id = way.id
                    let timestampString = dateFormatter.string(from: way.timestamp)
                    for tag in way.tags {
                        if(!tag.key.contains(".")){ // Do a utility function
                            storedWay.tags.setValue(tag.value, forKey: tag.key)
                        }
                    }
                    storedWay.version = way.version
                    storedWay.timestamp = timestampString
                    if let asWay = way as? OSMWay {
                        storedWay.nodes.append(objectsIn: asWay.nodes.map({Int64($0)}))
                        // Store the coordinates
//MARK: TBD polylines
//                        switch asWay.geometry {
//                        case .polygon(let coordinates):
//                            storedWay.polyline.append(objectsIn: coordinates)
//                        default:
//                            print("Ignoring geometry")
//                        }
                    }
                    realm.add(storedWay, update: .modified)
                }
            }
        } catch {
            print("Elements to be skipped or something happened")
        }
    }
    /**
            Earlier implementation of saveElements. This used to save only the Way type of objects.
            This is not used anymore
     */
//    func saveElements(_ elements: [OPWay]) {
//        do {
//            try realm.write {
//                for element in elements {
//                    let realmElement = RealmOPElement()
//                    realmElement.id = element.id
//                    realmElement.isInteresting = element.isInteresting
//                    realmElement.isSkippable = element.isSkippable
//                    
//                    let realmTags = element.tags.map { tag in
//                        let realmTag = RealmOPElementTag()
//                        realmTag.key = tag.key
//                        realmTag.value = tag.value
//                        return realmTag
//                    }
//                    realmElement.tags.append(objectsIn: realmTags)
//                    
//                    if let meta = element.meta {
//                        let realmMeta = RealmOPMeta()
//                        realmMeta.version = meta.version
//                        realmMeta.timestamp = meta.timestamp
//                        realmMeta.changeset = meta.changeset
//                        realmMeta.userId = meta.userId
//                        realmMeta.username = meta.username
//                        realmElement.meta = realmMeta
//                    } else {
//                        realmElement.meta = RealmOPMeta()
//                    }
//                    
//                    if !element.nodes.isEmpty {
//                        realmElement.nodes.append(objectsIn: element.nodes)
//                    }
//                    let geometry =  RealmOPGeometry(geometry: element.geometry)
//                    realmElement.geometry.append(geometry)
//                    realm.add(realmElement, update: .modified)
//                }
//                
//                
//            }
//        } catch {
//            print("Error saving elements to Realm: \(error)")
//        }
//    }
    func saveElements(_ elements: [OSMWay]) {
        do {
            try realm.write {
                for element in elements {
                    let realmElement = RealmOPElement()
                    realmElement.id = element.id
                    realmElement.isInteresting = element.isInteresting ?? false
                    realmElement.isSkippable = element.isSkippable ?? false
                    
                    let realmTags = element.tags.map { key, value in
                        let realmTag = RealmOPElementTag()
                        realmTag.key = key
                        realmTag.value = value
                        return realmTag
                    }
                    realmElement.tags.append(objectsIn: realmTags)
                    
                    let realmMeta = RealmOPMeta()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let dateString = dateFormatter.string(from: element.timestamp)
                    realmMeta.version = element.version
                    realmMeta.timestamp = dateString
                    realmMeta.changeset = element.changeset
                    realmMeta.userId = element.uid
                    realmMeta.username = element.user
                    realmElement.meta = realmMeta
                    
                    if !element.nodes.isEmpty {
                        realmElement.nodes.append(objectsIn: element.nodes)
                    }
                    
                    realm.add(realmElement, update: .modified)
                }
            }
        } catch {
            print("Error saving elements to Realm: \(error)")
        }
    }
    /**
     Fetches all the StoredNodes in the Database
     @returns a Results object containing StoredNodes
     */
    func getNodes() -> Results<StoredNode> {
        return realm.objects(StoredNode.self)
    }
    /**
    Fetches all the storedWays in the Database
     @returns a Results object containing StoredWay
     */
    func getWays() -> Results<StoredWay> {
        return realm.objects(StoredWay.self)
    }
    /**
     Fetches the center of a given StoredWay
     @param id String value of the way ID
     @returns CLLocationCoordinate2D the center location
     */
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
    /**
     Fetches a single node from the database
     @param id: String value of the node ID
     @return StoredNode
     */
    func getNode(id:String) -> StoredNode? {
        return realm.object(ofType: StoredNode.self, forPrimaryKey: Int(id))
    }
    /**
     Fetches single Way from the database
     @param id: String value of the wayId
     @return StoredWay
     */
    func getWay(id: String) -> StoredWay? {
        return realm.object(ofType: StoredWay.self, forPrimaryKey: Int(id))
    }
    /**
     Adds tags to the existing node and stores the same
     @param id : String value of the node ID
     @param tags [String:String] map of the added tags
     @return StoredNode
     */
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
    
    /**
     Adds tags to the existing way and stores the same
     @param id: String value of the way ID
     @param tags `[String:String]` map of the added tags
     @return `StoredWay`
     */
    func addWayTags(id: String, tags:[String:String]) -> StoredWay? {
        guard let theWay = getWay(id: id) else { return nil }
        
        do {
            try realm.write {
                tags.forEach { (key: String, value: String) in
                    theWay.tags.setValue(value, forKey: key)
                }
            }
        }
        catch {
            print("Error while writing tags")
        }
        return theWay
    }
    /**
     Creates a changeset for an element with specific ID. This does not store the updated nodes. That is to be done separately
     - parameter id: String id of the changed element
     - parameter type: StoredElementEnum type of the changed element (either way or node)
     - parameter tags [String:String] tags changed with this
     - Returns: An instance of `StoredChangeset`
        */
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
    /// Fetches the changeset objects from the database
    /// - parameter synced: Optional variable of whether synced or non synced
    /// - Returns: an instance of `Results<StoredChangeset>`
    func getChangesets(synced: Bool = false) -> Results<StoredChangeset> {
        
        if (synced == true){
            return  realm.objects(StoredChangeset.self).where({$0.changesetId != -1 })
        }
        return realm.objects(StoredChangeset.self).where({$0.changesetId == -1 })
    }
    /// Assigns changesetId for a stored changeset
    /// - parameter obj: Internal id for the changeset in the database (unique ID)
    /// - parameter changesetId: Assigned changeset ID from the server
    /// - Returns updated `StoredChangeset`
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
