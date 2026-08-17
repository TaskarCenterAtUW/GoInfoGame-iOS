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
        
    private init() {
        
    }
    
    /**
        Saves the OPElements into the database. This method does not remove the old data. However, it updates the
         data with same id
        @param elements  List of OPElement
     */
    func saveOSMElements(_ elements: [OSMElement]) {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        print("Realm path: \(realm.configuration.fileURL?.path ?? "No file URL")")

        // Build lookup and filter nodes
        var nodesDict: [Int: OSMNode] = [:]
        let nodes = elements.compactMap { element -> OSMNode? in
            guard let node = element as? OSMNode else { return nil }
            nodesDict[node.id] = node
            return node
        }

        let ways = elements.compactMap { element -> OSMWay? in
            guard let way = element as? OSMWay,
                  !way.tags.isEmpty,
                  way.tags["ext:link"] != "true" else {
                return nil
            }
            return way
        }

        // Prepare Realm objects outside write block
        let storedNodes: [StoredNode] = nodes.map { node in
            let stored = StoredNode()
            stored.id = Int64(node.id)
            let map = Map<String, String>()
            node.tags.forEach { key, value in
                map[key] = value
            }
            stored.tags = map
            stored.version = node.version
            stored.timestamp = node.timestamp
            stored.latitude = node.lat
            stored.longitude = node.lon
            return stored
        }

        let storedWays: [StoredWay] = ways.map { way in
            let stored = StoredWay()
            stored.id = Int64(way.id)
            let map = Map<String, String>()
            way.tags.forEach { key, value in
                if !key.contains(".") {
                    map[key] = value
                }
            }
            stored.tags = map
            stored.version = way.version
            stored.timestamp = way.timestamp
            stored.nodes.append(objectsIn: way.nodes.map(Int64.init))

            let polyline = List<CLLocationCoordinate2D>()
            for nodeId in way.nodes {
                if let node = nodesDict[nodeId] {
                    polyline.append(CLLocationCoordinate2D(latitude: node.lat, longitude: node.lon))
                }
            }
            stored.polyline = polyline
            return stored
        }

        // Persist to Realm
        do {
            realm.autorefresh = false
            try realm.write {
                realm.add(storedNodes, update: .all)
                realm.add(storedWays, update: .all)
            }
            realm.autorefresh = true
        } catch {
            print("❌ Realm write failed: \(error)")
        }
    }

    
    func clearDB() {
        do {
            let realm = try Realm(configuration: RealmConfig.configuration)
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Error clearing DB")
        }
    }
    
   

    func saveElements(_ elements: [OSMWay]) {
        do {
            let realm = try Realm(configuration: RealmConfig.configuration)
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
    
    func getNodes(_ predicate: NSPredicate) -> Results<StoredNode> {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredNode.self).filter(predicate)
    }
    /**
    Fetches all the storedWays in the Database
     @returns a Results object containing StoredWay
     */
    
    func getWays(_ predicate: NSPredicate) -> Results<StoredWay> {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredWay.self).filter(predicate)
    }
    
    func deleteWay(id: Int) {
        
        guard let realm = try? Realm(configuration: RealmConfig.configuration),
              let way = realm.object(ofType: StoredWay.self, forPrimaryKey: id) else {
            return
        }
        try? realm.write {
            realm.delete(way)
        }
    }
    
    func deleteNode(id: Int) {
        guard let realm = try? Realm(configuration: RealmConfig.configuration),
              let node = realm.object(ofType: StoredNode.self, forPrimaryKey: id) else {
            return
        }
        try? realm.write {
            realm.delete(node)
        }
    }
    
    func deleteChangesets(elementId: Int) {
        let predicateString = "elementId = \(elementId)"
        guard let realm = try? Realm(configuration: RealmConfig.configuration)else {
            return
        }
        let changesets = realm.objects(StoredChangeset.self).filter(NSPredicate(format: predicateString))
        if changesets.count == 0 {
            return
        }
        try? realm.write {
            for ch in changesets {
                realm.delete(ch)
            }
            
        }
    }
    /**
     Fetches the center of a given StoredWay
     @param id String value of the way ID
     @returns CLLocationCoordinate2D the center location
     */
    func getCenterForWay(id: Int64) -> CLLocationCoordinate2D? {
        // Get all the objects for the way
        let realm = try! Realm(configuration: RealmConfig.configuration)
       guard let way = realm.object(ofType: StoredWay.self, forPrimaryKey: id) else {
           return nil
       }
        let nodeIds = way.nodes
        // Get the nodes for each
        var nodeCoords: [CLLocationCoordinate2D] = []
        for nodeId in nodeIds {
            if let node = realm.object(ofType: StoredNode.self , forPrimaryKey: nodeId){
                nodeCoords.append(CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude))
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.object(ofType: StoredNode.self, forPrimaryKey: id)
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.object(ofType: StoredWay.self, forPrimaryKey: id)
    }

    
    
    
    

    
    /**
     Adds tags to the existing way and stores the same
     @param id: String value of the way ID
     @param tags `[String:String]` map of the added tags
     @return `StoredWay`
     */    
    func addWayTags(id: Int, tags: [String: String], version: Int, timestamp: Date? = nil) -> StoredWay? {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        // Step 1: Try to get the editable copy first
        if let editable = getWay(id: id) {
            // Step 2: Update the existing editable copy
            do {
                try realm.write {
                    editable.tags.removeAll()
                    // An empty value means the tag was cleared/removed this submission
                    // (see OSMWay.toPayload) — the local cache should reflect that the
                    // tag no longer exists at all, not carry a phantom empty entry.
                    tags.forEach { key, value in
                        guard !value.isEmpty else { return }
                        editable.tags[key] = value
                    }
                    editable.version = version
                    if let timestamp {
                        editable.timestamp = timestamp
                    }
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
    func addNodeTags(id: Int, tags: [String: String], version: Int, timestamp: Date? = nil) -> StoredNode? {
        print("🟣 addNodeTags called for id: \(id) with tags: \(tags)")
        let realm = try! Realm(configuration: RealmConfig.configuration)
        if let editable = getNode(id: id) {
            print("✏️ Editable node exists: \(editable.id)")
            do {
                try realm.write {
                    editable.tags.removeAll()
                    // See the equivalent comment in addWayTags: an empty value means
                    // the tag was cleared this submission — drop it from the local
                    // cache entirely rather than storing a phantom empty entry.
                    tags.forEach { key, value in
                        guard !value.isEmpty else { return }
                        editable.tags[key] = value
                    }
                    editable.version = version
                    if let timestamp {
                        editable.timestamp = timestamp
                    }
                }
                print("✅ Updated editable node.")
            } catch {
                print("❌ Error while writing node tags: \(error)")
            }
            return editable
        }
        return nil
    }




    
    
    /// Records a brand-new node (created via Add Feature) as an already-"synced"
    /// changeset — there's nothing pending to upload since `createNode` already
    /// completed the real create synchronously — purely so it immediately appears in
    /// `MapUndoManager.getUndoItems()`. `originalTags` is intentionally left empty
    /// (nothing existed before this element), and `isCreatedElement` is what
    /// `QuestBase.updateUndoTags` checks to delete the node on undo instead of
    /// restoring old tags. Deliberately separate from `createChangeset` below, which
    /// backs the unrelated "pending edit to an existing element" queue that
    /// `DatasyncManager.syncData()` drains — a create must never end up in that queue.
    func createChangesetForNewElement(id: Int, questType: String, tags: [String: String], version: Int, iconName: String, point: CLLocationCoordinate2D) -> StoredChangeset? {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let storedChangeset = StoredChangeset()
        storedChangeset.elementId = id
        storedChangeset.elementType = .node
        storedChangeset.version = version
        storedChangeset.updatedVersion = version // already synced — nothing for syncData() to do
        storedChangeset.changesetId = 0          // matches the "synced, undoable" sentinel getUndoItems() checks for
        storedChangeset.questType = questType
        storedChangeset.iconName = iconName
        storedChangeset.point = point
        storedChangeset.isCreatedElement = true
        storedChangeset.timestamp = String(Date().timeIntervalSince1970)
        for tag in tags {
            storedChangeset.tags.setValue(tag.value, forKey: tag.key)
        }
        // originalTags left empty — nothing existed before this element was created.

        do {
            try realm.write {
                realm.add(storedChangeset)
            }
        } catch {
            print("Error while writing the create changeset")
            return nil
        }
        return storedChangeset
    }

    /**
     Creates a changeset for an element with specific ID. This does not store the updated nodes. That is to be done separately
     - parameter id: String id of the changed element
     - parameter type: StoredElementEnum type of the changed element (either way or node)
     - parameter tags [String:String] tags changed with this
     - Returns: An instance of `StoredChangeset`
        */
    func createChangeset(id:Int, questType: String, type: StoredElementEnum, originalTags:[String:String], tags:[String:String], version: Int, iconName: String, point: CLLocationCoordinate2D? = nil, nodes: List<Int64>? = nil) -> StoredChangeset? {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let storedChangeset = StoredChangeset()
        storedChangeset.elementId = id
        storedChangeset.elementType = type
        storedChangeset.version = version
        storedChangeset.questType = questType
        storedChangeset.iconName = iconName
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let predicateString = synced ? "updatedVersion != -1" : "updatedVersion == -1"
        return realm.objects(StoredChangeset.self).filter(NSPredicate(format: predicateString))
    }
    
    func getChangesets(synced: Bool, element: ElementType) -> Results<StoredChangeset> {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let syncString = synced ? "updatedVersion != -1" : "updatedVersion == -1"
        let predicateString = "\(syncString) AND elementType == \"\(element)\""
        return realm.objects(StoredChangeset.self).filter(NSPredicate(format: predicateString))
    }
    
    func getChangeset(for id: String) -> StoredChangeset? {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.object(ofType: StoredChangeset.self, forPrimaryKey: id)
    }

    /// Assigns changesetId for a stored changeset
    /// - parameter obj: Internal id for the changeset in the database (unique ID)
    /// - parameter changesetId: Assigned changeset ID from the server
    /// - Returns updated `StoredChangeset`
    func assignChangesetId(obj:String, changesetId: Int, updatedVersion: Int) -> StoredChangeset? {
        let realm = try! Realm(configuration: RealmConfig.configuration)
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
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
        let realm = try! Realm(configuration: RealmConfig.configuration)
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

    // MARK: - Note drafts (offline queue for Create Note)

    /// Creates the pending note draft, or if `id` already exists (a retry of a
    /// previously failed draft), overwrites its text/photos/coordinates in place.
    @discardableResult
    func upsertNoteDraft(id: String, noteText: String, imagePaths: [String], coordinates: CLLocationCoordinate2D) -> StoredNoteDraft {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let draft = StoredNoteDraft()
        draft.id = id
        draft.noteText = noteText
        draft.imagePaths.append(objectsIn: imagePaths)
        draft.latitude = coordinates.latitude
        draft.longitude = coordinates.longitude
        draft.createdAt = Date()
        try! realm.write {
            realm.add(draft, update: .modified)
        }
        return draft
    }

    /// All notes still waiting to be uploaded/submitted, oldest first.
    func pendingNoteDrafts() -> [StoredNoteDraftSnapshot] {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredNoteDraft.self)
            .sorted(byKeyPath: "createdAt")
            .map {
                StoredNoteDraftSnapshot(
                    id: $0.id,
                    noteText: $0.noteText,
                    imagePaths: Array($0.imagePaths),
                    coordinates: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                )
            }
    }

    func pendingNoteDraftsCount() -> Int {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredNoteDraft.self).count
    }

    func noteDraftImagePaths(id: String) -> [String] {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredNoteDraft.self, forPrimaryKey: id) else { return [] }
        return Array(draft.imagePaths)
    }

    func deleteNoteDraft(id: String) {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredNoteDraft.self, forPrimaryKey: id) else { return }
        try! realm.write {
            realm.delete(draft)
        }
    }

    func markNoteDraftFailed(id: String, error: String) {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredNoteDraft.self, forPrimaryKey: id) else { return }
        try! realm.write {
            draft.lastError = error
            draft.retryCount += 1
        }
    }

    // MARK: - Feature drafts (offline queue for Add Feature)

    /// Creates the pending feature draft, or if `id` already exists (a retry of a
    /// previously failed draft), overwrites its tags/photos/coordinates in place.
    @discardableResult
    func upsertFeatureDraft(id: String, presetName: String, iconName: String, tags: [String: String], imagePaths: [String], coordinates: CLLocationCoordinate2D) -> StoredFeatureDraft {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        let draft = StoredFeatureDraft()
        draft.id = id
        draft.presetName = presetName
        draft.iconName = iconName
        for (key, value) in tags {
            draft.tags.setValue(value, forKey: key)
        }
        draft.imagePaths.append(objectsIn: imagePaths)
        draft.latitude = coordinates.latitude
        draft.longitude = coordinates.longitude
        draft.createdAt = Date()
        try! realm.write {
            realm.add(draft, update: .modified)
        }
        return draft
    }

    /// All features still waiting to be uploaded/created, oldest first.
    func pendingFeatureDrafts() -> [StoredFeatureDraftSnapshot] {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredFeatureDraft.self)
            .sorted(byKeyPath: "createdAt")
            .map {
                StoredFeatureDraftSnapshot(
                    id: $0.id,
                    presetName: $0.presetName,
                    iconName: $0.iconName,
                    tags: $0.tags.toDictionary(),
                    imagePaths: Array($0.imagePaths),
                    coordinates: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                )
            }
    }

    func pendingFeatureDraftsCount() -> Int {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        return realm.objects(StoredFeatureDraft.self).count
    }

    func featureDraftImagePaths(id: String) -> [String] {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredFeatureDraft.self, forPrimaryKey: id) else { return [] }
        return Array(draft.imagePaths)
    }

    func deleteFeatureDraft(id: String) {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredFeatureDraft.self, forPrimaryKey: id) else { return }
        try! realm.write {
            realm.delete(draft)
        }
    }

    func markFeatureDraftFailed(id: String, error: String) {
        let realm = try! Realm(configuration: RealmConfig.configuration)
        guard let draft = realm.object(ofType: StoredFeatureDraft.self, forPrimaryKey: id) else { return }
        try! realm.write {
            draft.lastError = error
            draft.retryCount += 1
        }
    }

}

struct RealmConfig {
    static let configuration = Realm.Configuration(schemaVersion: 3) { migration, oldSchemaVersion in
        if oldSchemaVersion < 1 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            migration.enumerateObjects(ofType: StoredNode.className()) { oldObject, newObject in
                if let oldTimestamp = oldObject?["timestamp"] as? String {
                    if let date = formatter.date(from: oldTimestamp) {
                        newObject?["timestamp"] = date
                    } else {
                        newObject?["timestamp"] = Date()
                    }
                }
                
                if let oldPoint = oldObject!["point"] as? MigrationObject {
                    // Access latitude and longitude from the old 'point' MigrationObject
                    // Realm automatically stores CLLocationCoordinate2D with 'latitude' and 'longitude' properties
                    let latitude = oldPoint["latitude"] as? Double ?? 0.0
                    let longitude = oldPoint["longitude"] as? Double ?? 0.0

                    // Assign these values to the new 'latitude' and 'longitude' properties
                    newObject?["latitude"] = latitude
                    newObject?["longitude"] = longitude
                }
            }
        } else if oldSchemaVersion < 2 {
            migration.enumerateObjects(ofType: StoredChangeset.className()) { oldObject, newObject in
                newObject?["questType"] = nil
                newObject?["iconName"] = "notes"
            }
        }
        if oldSchemaVersion < 3 {
            // Every changeset that existed before this field was added is, by
            // definition, an edit to an already-existing element — never a create.
            migration.enumerateObjects(ofType: StoredChangeset.className()) { _, newObject in
                newObject?["isCreatedElement"] = false
            }
        }
    }
}

