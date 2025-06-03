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
import osmparser

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
    func saveOSMElements(_ elements: [OSMElement]) {
        // Save the elements appropriately
        // Get the ways and nodes out
        let nodes = elements.filter({$0 is OSMNode})
        let nodesOnly = elements.filter({$0 is OSMNode})
        // Create a dictionary out of this like [id : osmnode]
        var nodesDict: [String:OSMNode] = [:]
        nodesOnly.forEach { element in
            nodesDict[String(element.id)] = element as? OSMNode
        }
        
        let ways = elements.filter { element in
            guard let way = element as? OSMWay else {
                return false
            }
            return !way.tags.isEmpty && !(way.tags["ext:link"] == "true")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        do {
            try realm.write {
                for node in nodes {
                    let storedElement = StoredNode()
                    storedElement.id = node.id
                    storedElement.tags.removeAll()
                    node.tags.forEach { key, value in
                        storedElement.tags[key] = value
                    }
//                    if let meta = node {
                        let timestampString = dateFormatter.string(from: node.timestamp)
                        storedElement.version = node.version
                        storedElement.timestamp = timestampString
                        storedElement.isOriginal = true
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
                    storedElement.generateCompoundId()
                    realm.add(storedElement, update: .all)
                }
                // Store the ways
                for way in ways {
                    let storedWay = StoredWay()
                    storedWay.id = way.id
                    let timestampString = dateFormatter.string(from: way.timestamp)
                    storedWay.tags.removeAll()
                    way.tags.forEach { key, value in
                        if !key.contains(".") {
                            storedWay.tags[key] = value
                        }
                    }
                    storedWay.version = way.version
                    storedWay.timestamp = timestampString
                    storedWay.isOriginal = true
                    if let asWay = way as? OSMWay {
                        storedWay.nodes.append(objectsIn: asWay.nodes.map({Int64($0)}))
                        // Get all the points for the p
                        var nodesInWay = List<CLLocationCoordinate2D>()
                        asWay.nodes.forEach { nodeId in
                            if let actualNode = nodesDict[String(nodeId)] {
                                nodesInWay.append(CLLocationCoordinate2D(latitude: actualNode.lat, longitude: actualNode.lon))
                            }
                            
                        }
                        storedWay.polyline = nodesInWay
//                        print("STORED POLYLINES --->>>\(storedWay.polyline)")
                        // Store the coordinates
//MARK: TBD polylines
//                        switch asWay.geometry {
//                        case .polygon(let coordinates):
//                            storedWay.polyline.append(objectsIn: coordinates)
//                        default:
//                            print("Ignoring geometry")
//                        }
                    }
                    storedWay.generateCompoundId()
                    realm.add(storedWay, update: .all)
                }
            }
        } catch {
            print("Elements to be skipped or something happened")
        }
    }
    
    func clearDB() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Error clearing DB")
        }
    }
    
   

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
                    
                    realm.add(realmElement, update: .all)
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
        let compoundId = "\(id)-original" //
           guard let way = realm.object(ofType: StoredWay.self, forPrimaryKey: compoundId) else {
               return nil
           }
        let nodeIds = way.nodes
        // Get the nodes for each
        var nodeCoords: [CLLocationCoordinate2D] = []
        for nodeId in nodeIds {
            let compoundNodeId = "\(nodeId)-original"
            if let node = realm.object(ofType: StoredNode.self , forPrimaryKey: compoundNodeId){
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
    func getNode(id:Int) -> StoredNode? {
        let compoundId = "\(id)"
        return realm.object(ofType: StoredNode.self, forPrimaryKey: compoundId)
    }
    /**
     Fetches single Way from the database
     @param id: String value of the wayId
     @return StoredWay
     */
//    func getWay(id: String) -> StoredWay? {
//        return realm.object(ofType: StoredWay.self, forPrimaryKey: Int(id))
//    }
    
    func getWay(id: Int) -> StoredWay? {
        let compoundId = "\(id)"
        return realm.object(ofType: StoredWay.self, forPrimaryKey: compoundId)
    }

    
    
    
    

    
    /**
     Adds tags to the existing way and stores the same
     @param id: String value of the way ID
     @param tags `[String:String]` map of the added tags
     @return `StoredWay`
     */    
    func addWayTags(id: Int, tags: [String: String], version: Int) -> StoredWay? {

        // Step 1: Try to get the editable copy first
        if let editable = getWay(id: id) {
            // Step 2: Update the existing editable copy
            do {
                try realm.write {
                    editable.tags.removeAll()
                    tags.forEach { editable.tags[$0.key] = $0.value }
                    editable.version = version
                }
            } catch {
                print("Error while writing tags")
            }
            return editable
        }
        return nil
    }
    
    
    /**
     Adds tags to the existing node and stores the same
     @param id : String value of the node ID
     @param tags [String:String] map of the added tags
     @return StoredNode
     */
    func addNodeTags(id: Int, tags: [String: String], version: Int) -> StoredNode? {
        print("🟣 addNodeTags called for id: \(id) with tags: \(tags)")

        if let editable = getNode(id: id) {
            print("✏️ Editable node exists: \(editable.compoundId)")
            do {
                try realm.write {
                    editable.tags.removeAll()
                    tags.forEach { editable.tags[$0.key] = $0.value }
                    editable.version = version
                }
                print("✅ Updated editable node.")
            } catch {
                print("❌ Error while writing node tags: \(error)")
            }
            return editable
        }
        return nil
    }




    
    
    /**
     Creates a changeset for an element with specific ID. This does not store the updated nodes. That is to be done separately
     - parameter id: String id of the changed element
     - parameter type: StoredElementEnum type of the changed element (either way or node)
     - parameter tags [String:String] tags changed with this
     - Returns: An instance of `StoredChangeset`
        */
    func createChangeset(id:Int, type: StoredElementEnum, originalTags:[String:String], tags:[String:String], version: Int, point: CLLocationCoordinate2D? = nil, nodes: List<Int64>? = nil) -> StoredChangeset? {
        let storedChangeset = StoredChangeset()
        storedChangeset.elementId = id
        storedChangeset.elementType = type
        storedChangeset.version = version
        if let point = point {
            storedChangeset.point = point
        }
        if let nodes = nodes {
            storedChangeset.nodes = nodes
        }
        
        storedChangeset.timestamp =  String(Date().timeIntervalSince1970)
        for tag in tags {
            storedChangeset.tags.setValue(tag.value, forKey: tag.key)
        }
        
        for tag in originalTags {
            storedChangeset.originalTags.setValue(tag.value, forKey: tag.key)
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
        let results: Results<StoredChangeset>
        if synced {
            results = realm.objects(StoredChangeset.self).where { $0.changesetId != -1 }
        } else {
            results = realm.objects(StoredChangeset.self).where { $0.changesetId == -1 }
        }
        print("Found \(results.count) changesets for synced=\(synced)")
        return results
    }
    
    func getChangeset(for id: String) -> StoredChangeset? {
        return realm.object(ofType: StoredChangeset.self, forPrimaryKey: id)
    }

    /// Assigns changesetId for a stored changeset
    /// - parameter obj: Internal id for the changeset in the database (unique ID)
    /// - parameter changesetId: Assigned changeset ID from the server
    /// - Returns updated `StoredChangeset`
    func assignChangesetId(obj:String, changesetId: Int, updatedVersion: Int) -> StoredChangeset? {
        guard let changeset = realm.object(ofType: StoredChangeset.self, forPrimaryKey: obj) else {
            return nil
        }
        do {
            try realm.write {
                changeset.changesetId = changesetId // Not sure if this changes the value
                changeset.updatedVersion = updatedVersion
            }
            return changeset
        } catch (let error){
            return nil
        }
    }
    
    func updateChangesetWithUndoResultSuccess(obj:String) -> StoredChangeset? {
        guard let changeset = realm.object(ofType: StoredChangeset.self, forPrimaryKey: obj) else {
            return nil
        }
        do {
            try realm.write {
                changeset.undoOn = Date()
                changeset.isUndoCompleted = true
            }
            return changeset
        } catch (let error){
            return nil
        }
    }
    
    func updateNodeVersion(nodeId: String, version:Int) -> StoredNode?{
        let intId = Int(nodeId) ?? -1
        guard let theNode = getNode(id: intId) else { return nil }
        do {
            try realm.write {
                theNode.version = version
            }
        }
        catch {
            print("Error while assigning version")
        }
        
        return theNode
    }
    
    func updateWayVersion(wayId: String, version: Int) -> StoredWay? {
        let intId = Int(wayId) ?? -1
        guard let theWay = getWay(id: intId) else { return nil }
        
        do {
            try realm.write {
                theWay.version = version
            }
        }
        catch {
            print("Error while assigning version")
        }
        
        return theWay
    }

}
