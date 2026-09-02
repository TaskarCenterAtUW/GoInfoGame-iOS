//
//  DatasyncManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 1/29/24.
//
// Syncs the data from the user input to the POSM

import Foundation
import Realm
import osmapi

class DatasyncManager {
    
    static let shared = DatasyncManager()
    private init() {}
    
    private var isSynching: Bool = false
    
    private let dbInstance = DatabaseConnector.shared
    private let barrierQueue: DispatchQueue = DispatchQueue(label: "com.goinfogame.DatasyncManager.barrierQueue", attributes: .concurrent)

    /// Mirrors the selected workspace's `overrideConflicts` flag (persisted by
    /// `InitialViewModel.fetchLongQuestsFor` from the workspace-details API).
    /// When true, tag conflicts on sync are auto-resolved with local values
    /// winning instead of showing the `ConflictResolutionSheet`.
    private var overrideConflicts: Bool {
        UserDefaults.standard.bool(forKey: "workspace_overrideConflicts")
    }
    
    func syncDataToOSM(exclude_gig_tags: Bool, completionHandler: @escaping (Result<Bool, APIError>)  -> Void) {
        let currentQueue = OperationQueue.current?.underlyingQueue ?? .main
        
        barrierQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            
            Task.detached(priority: .userInitiated) {
                do {
                    let isSynced = try await self.syncData(exclude_gig_tags: exclude_gig_tags)
                    
                    print("Sync finished")
                    currentQueue.async {
                        if isSynced {
                            print("Sync successful")
                            completionHandler(.success(true)) // Success
                        } else {
                            print("Sync failed")
                            completionHandler(.failure(APIError.custom("Sync failed. Please try again."))) // Failure
                        }
                    }
                } catch {
                    currentQueue.async {
                        print("Sync failed: \(error)")
                        completionHandler(.failure(error as! APIError)) // Failure
                    }
                }
                semaphore.signal()
            }
            
            semaphore.wait()
        }
    }
    
    /// *** Terminating app due     to uncaught exception 'RLMException', reason: 'Realm accessed from incorrect thread.'
    ///  To fix the above error added @mainActor
    func syncData(exclude_gig_tags: Bool = false) async throws -> Bool {
        print("🔄 Starting sync...")

        let changesets = dbInstance.getChangesets()
        print("Found \(changesets.count) changesets for synced=false")

        // Filter changesets that have valid edited versions
        let validChangesets = changesets.filter {
            let intId = Int($0.elementId)
            switch $0.elementType {
            case .way:
                let exists = self.dbInstance.getWay(id: intId) != nil
                if !exists {
                    print("⚠️ Edited way not found for ID: \(intId)")
                }
                return exists
            case .node:
                let exists = self.dbInstance.getNode(id: intId) != nil
                if !exists {
                    print("⚠️ Edited node not found for ID: \(intId)")
                }
                return exists
            default:
                return false
            }
        }

        print("📦 Found \(validChangesets.count) unsynced changesets with valid edits")

        var nodesToSync: [String: OSMNode] = [:]
        var waysToSync: [String: OSMWay] = [:]
        var changesetMetadata: [String: (elementTypeName: String, iconName: String)] = [:]

        for cs in validChangesets {
            changesetMetadata[cs.id] = (cs.questType ?? "Element", cs.iconName)
            if cs.elementType == .node {
                nodesToSync[cs.id] = cs.asOSMNode()
            } else if cs.elementType == .way {
                waysToSync[cs.id] = cs.asOSMWay()
            }
        }

        var syncSuccess = true

        if nodesToSync.isEmpty && waysToSync.isEmpty {
            print("✅ No edited elements found to sync")
            return true
        }

        for (key, node) in nodesToSync {
//            print("📤 Syncing node ID: \(node.id)")
            let payload = node
            let meta = changesetMetadata[key]
            do {
                let status = try await syncNode(node: payload, exclude_gig_tags: exclude_gig_tags, editedTags: node.tags, elementTypeName: meta?.elementTypeName ?? "Element", iconName: meta?.iconName ?? "notes")
                if status.result {
                    _ = self.dbInstance.assignChangesetId(obj: key, changesetId: 0, updatedVersion: status.version)
                    print("✅ Node sync finished: \(payload.id)")
                } else {
                    print("❌ Node sync failed silently: \(payload.id)")
                    syncSuccess = false
                }
            } catch {
                print("❌ Failed to sync node: \(error.localizedDescription)")
                syncSuccess = false
                throw error
            }
        }

        for (key, way) in waysToSync {
//            print("📤 Syncing way ID: \(way.id)")
            let payload = way
            let meta = changesetMetadata[key]
            do {
                let status = try await syncWay(way: payload, exclude_gig_tags: exclude_gig_tags, editedTags: way.tags, elementTypeName: meta?.elementTypeName ?? "Element", iconName: meta?.iconName ?? "notes")
                if status.result {
                    _ = self.dbInstance.assignChangesetId(obj: key, changesetId: 0, updatedVersion: status.version)
                    print("✅ Way sync finished: \(payload.id)")
                } else {
                    print("❌ Way sync failed silently: \(payload.id)")
                    syncSuccess = false
                }
            } catch {
                print("❌ Failed to sync way: \(error.localizedDescription)")
                syncSuccess = false
                throw error
            }
        }

        print("Sync finished")
        return syncSuccess
    }



    func refreshOriginalWayIfNewer(_ newWay: OSMWay) {
        guard let existing = DatabaseConnector.shared.getWay(id: newWay.id) else {
            DatabaseConnector.shared.saveOSMElements([newWay])
            return
        }

        if newWay.version > existing.version {
            DatabaseConnector.shared.saveOSMElements([newWay])
        }
    }
    
    func refreshOriginalNodeIfNewer(_ newNode: OSMNode) {
        guard let existing = DatabaseConnector.shared.getNode(id: newNode.id) else {
            DatabaseConnector.shared.saveOSMElements([newNode])
            return
        }

        if newNode.version > existing.version {
            DatabaseConnector.shared.saveOSMElements([newNode])
        }
    }
    
    func dummyTask() async -> Result<Bool,Error> {
        do {
            try await Task.sleep(nanoseconds: UInt64(3 * 1_000_000_000))
            return .success(true)
        }catch (let e){
            return .failure(e)
        }
    }
    
    func openChangeset(exclude_gig_tags: Bool = false) async throws -> Int {
        var versionNumber = ""
        var buildNumber = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionNumber = version
            buildNumber = build
        }
        
        let createdBy = "\(versionNumber)(\(buildNumber))"
        let osmPayloadString = OSMChangesetPayload(createdByTag: createdBy).toPayload(exclude_gig_tags: exclude_gig_tags)
        let osmPayload = osmPayloadString.data(using: .utf8)
        let workspaceId = KeychainManager.load(key: "workspaceID")
        
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
               throw NSError(domain: "NoAccessToken", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Access Token found"])
           }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .openChangesets(accessToken, workspaceId ?? "", osmPayload!),setupType: .osm, modelType: Int.self) { result in
                switch result {
                case .success(let changesetID):
                    SyncLogger.shared.logStep("✅ Created changeset. ID = \(changesetID)")
                    continuation.resume(returning: changesetID)
                case .failure(let error):
                    SyncLogger.shared.logStep("❌ Failed to create changeset: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func closeChangeset(id: String) async throws -> Bool {
        let workspaceId = KeychainManager.load(key: "workspaceID")
        
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw NSError(domain: "NoAccessToken", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Access Token found"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .closeChangeset(id, workspaceId ?? "", accessToken), setupType: .osm, modelType: Bool.self) { result in
                switch result {
                case .success(let closedResult):
                    SyncLogger.shared.logStep("Changeset closed")
                    continuation.resume(returning: closedResult)
                    
                case .failure(let error):
                    SyncLogger.shared.logStep("Closing Changeset Failed ---\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
        
    }

    // utility function to act as substitute for osmConnection functions
    func updateWay(way: OSMWay, exclude_gig_tags: Bool) async throws -> Int {
        var localWay = way
        let wayBodyString = localWay.toPayload(exclude_gig_tags: exclude_gig_tags)
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + wayBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")
        let wayBody = changesetUploadBody.data(using: .utf8)
        let newVersion = way.version + 1
        print("Uploading changeset \(changesetUploadBody)")
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw NSError(domain: "No AccessToken", code: 0, userInfo: nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(
                to: .uploadChangeset(accessToken, "\(way.changeset)", workspaceId ?? "", wayBody!),
                setupType: .osm,
                modelType: String.self,
                useJSON: false
            ) { result in
                switch result {
                case .success:
                    localWay.tags.forEach { (key: String, value: String) in
                        localWay.tags[key] = value
                    }
                    let id = localWay.id
                    let tags = localWay.tags
                    // The OSM API's changeset-upload response doesn't echo back a
                    // fresh server timestamp for a <modify>, so stamp local "now" —
                    // it's overwritten with the real server value on the next full
                    // fetch/sync of this element, and this keeps a just-answered
                    // element from looking stale in the meantime.
                    _ = DatabaseConnector.shared.addWayTags(id: id, tags: tags, version: newVersion, timestamp: Date())
                    continuation.resume(returning: newVersion)

                case .failure(let error):
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
  
    // utility function to act as substitute for osmConnection functions
    func updateNode(node: OSMNode, exclude_gig_tags: Bool) async throws -> Int {
        let localNode = node
        let nodeBodyString = localNode.toPayload(exclude_gig_tags: exclude_gig_tags)
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + nodeBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            throw NSError(domain: "Invalid Node Body", code: 0, userInfo: nil)
        }
        print("Uploading changeset \(changesetUploadBody)")

        let newVersion = localNode.version + 1

        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw NSError(domain: "No AccessToken", code: 0, userInfo: nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(
                to: .uploadChangeset(accessToken, "\(localNode.changeset)", workspaceId ?? "", nodeBody),
                setupType: .osm,
                modelType: String.self,
                useJSON: false
            ) { result in
                switch result {
                case .success:
                    var updatedNode = localNode
                    updatedNode.tags.forEach { (key: String, value: String) in
                        updatedNode.tags[key] = value
                    }
                    updatedNode.version = newVersion
                    SyncLogger.shared.logStep("Node Updated ----\(updatedNode.tags)")

                    // See the equivalent comment in updateWay: no fresh server
                    // timestamp comes back from a <modify>, so stamp local "now".
                    _ = DatabaseConnector.shared.addNodeTags(id: updatedNode.id, tags: updatedNode.tags, version: newVersion, timestamp: Date())
                    continuation.resume(returning: newVersion)
                case .failure(let error):
                    print(error)
                    SyncLogger.shared.logStep("❌ Node updation failed ----\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// The server-assigned id/version for a node just created via `uploadNode`/`createNode` —
    /// the OSM API never echoes these back except inside the changeset upload's diffResult
    /// XML, so they have to be parsed out of it explicitly.
    struct CreatedElementResult {
        let id: Int
        let version: Int
    }

    /// Reads `<node old_id="-1" new_id="…" new_version="…"/>` out of a changeset upload's
    /// diffResult response. The client always uploads new nodes under the placeholder
    /// id "-1" (`OSMNode.toCreatePayload`), so `new_id`/`new_version` are the only way to
    /// learn the real id/version the server assigned.
    private final class CreateNodeDiffResultParser: NSObject, XMLParserDelegate {
        private(set) var result: CreatedElementResult?

        func parse(_ xmlString: String) -> CreatedElementResult? {
            guard let data = xmlString.data(using: .utf8) else { return nil }
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            return result
        }

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            guard elementName == "node",
                  let newIdString = attributeDict["new_id"], let newId = Int(newIdString),
                  let newVersionString = attributeDict["new_version"], let newVersion = Int(newVersionString)
            else { return }
            result = CreatedElementResult(id: newId, version: newVersion)
        }
    }

    func uploadNode(node: OSMNode, exclude_gig_tags: Bool = false) async throws -> CreatedElementResult {
        let localNode = node
        let nodeBodyString = localNode.toCreatePayload(exclude_gig_tags: exclude_gig_tags)
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + nodeBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            throw APIError.decodingFailed("Invalid Node Body")
        }

        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw APIError.unauthorized
        }

        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .uploadChangeset(accessToken, "\(node.changeset)", workspaceId ?? "", nodeBody), setupType: .osm, modelType: String.self, useJSON: false) { result in
                switch result {
                case .success(let diffResultXML):
                    guard let created = CreateNodeDiffResultParser().parse(diffResultXML) else {
                        continuation.resume(throwing: APIError.decodingFailed("Could not read the new node's id from the server response"))
                        return
                    }
                    continuation.resume(returning: created)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    /// Thrown when the user cancels the interactive conflict-resolution prompt raised from
    /// `updateNode2`/`updateWay2`. Caught in `syncNode`/`syncWay` to leave the changeset unsynced
    /// without aborting the rest of the sync batch.
    enum SyncConflictError: Error {
        case cancelledByUser
    }

    /// Shows the per-tag conflict-resolution sheet and waits for the user's decision.
    /// Returns the resolved tag set (same keys as `editedTags`, conflicting values replaced per the
    /// user's choice), or nil if the user cancelled.
    private func promptForConflictResolution(elementId: Int64, elementTypeName: String, iconName: String, editedTags: [String: String], conflicts: [ConflictingTag]) async -> [String: String]? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                MapViewPublisher.shared.conflictDetected.send(
                    PendingSyncConflict(elementId: elementId, elementTypeName: elementTypeName, iconName: iconName, conflicts: conflicts) { decision in
                        switch decision {
                        case .cancelled:
                            continuation.resume(returning: nil)
                        case .resolved(let choices):
                            var resolvedTags = editedTags
                            for conflict in conflicts {
                                switch choices[conflict.key] {
                                case .useServer:
                                    resolvedTags[conflict.key] = conflict.existingValue
                                case .useMine, .none:
                                    resolvedTags[conflict.key] = conflict.answeredValue
                                }
                            }
                            continuation.resume(returning: resolvedTags)
                        }
                    }
                )
            }
        }
    }

    func updateWay2(way: OSMWay, exclude_gig_tags: Bool, editedTags: [String : String], elementTypeName: String = "Element", iconName: String = "notes") async throws -> Int {
        var localWay = way
        var currentEditedTags = editedTags
        let wayId = "\(localWay.id)"

        while true {
            do {
                return try await updateWay(way: localWay, exclude_gig_tags: exclude_gig_tags)
            } catch let error as APIError {
                guard case .conflict = error else { throw error }

                do {
                    let latestWay = try await fetchway2(wayId: wayId)
                    dbInstance.saveOSMElements([latestWay])

                    if exclude_gig_tags {
                        guard let mergedWay = self.mergeWays(localWay: localWay, latestWay: latestWay, exclude_gig_tags: exclude_gig_tags, editedTags: currentEditedTags) else {
                            print("Undo operation is not possible")
                            return latestWay.version
                        }
                        return try await updateWay(way: mergedWay, exclude_gig_tags: exclude_gig_tags)
                    }

                    var mergedWay = latestWay
                    mergedWay.changeset = localWay.changeset

                    if overrideConflicts {
                        // Workspace opted out of interactive conflict resolution: reinstate the
                        // pre-ConflictResolutionSheet behaviour — union the tags with every local
                        // value overriding the server, then retry on the fresh version.
                        for (key, value) in localWay.tags { mergedWay.tags[key] = value }
                        localWay = mergedWay
                        continue
                    }

                    let conflicts = currentEditedTags.compactMap { key, answeredValue -> ConflictingTag? in
                        guard let existingValue = latestWay.tags[key], existingValue != answeredValue else { return nil }
                        return ConflictingTag(key: key, existingValue: existingValue, answeredValue: answeredValue)
                    }

                    if conflicts.isEmpty {
                        for (key, value) in currentEditedTags { mergedWay.tags[key] = value }
                        localWay = mergedWay
                        continue // version moved but nothing we touched actually conflicts; retry on the new version
                    }

                    guard let resolvedTags = await promptForConflictResolution(
                        elementId: Int64(localWay.id), elementTypeName: elementTypeName, iconName: iconName,
                        editedTags: currentEditedTags, conflicts: conflicts
                    ) else {
                        throw SyncConflictError.cancelledByUser
                    }

                    currentEditedTags = resolvedTags
                    for (key, value) in resolvedTags { mergedWay.tags[key] = value }
                    localWay = mergedWay
                    // loop back and retry with the resolved tags on the latest version; if someone edits
                    // again while the user was deciding, this lands back here and re-prompts with fresh data
                } catch let error as APIError {
                    if case .deleted = error {
                        dbInstance.deleteChangesets(elementId: way.id)
                        dbInstance.deleteWay(id: way.id)
                        DispatchQueue.main.async {
                            QuestsPublisher.shared.elementDeleted.send(way.id)
                        }
                    }
                    throw error
                }
            }
        }
    }

    func updateNode2(node: OSMNode, exclude_gig_tags: Bool, editedTags: [String : String], elementTypeName: String = "Element", iconName: String = "notes") async throws -> Int {
        var localNode = node
        var currentEditedTags = editedTags
        let nodeId = "\(localNode.id)"
        SyncLogger.shared.logStep("Updating node \(nodeId) under new changeset")

        while true {
            do {
                return try await updateNode(node: localNode, exclude_gig_tags: exclude_gig_tags)
            } catch let error as APIError {
                guard case .conflict = error else { throw error }

                do {
                    SyncLogger.shared.logStep("Fetching node due to conflict")
                    let latestNode = try await fetchNode2(nodeId: nodeId)
                    dbInstance.saveOSMElements([latestNode])

                    if exclude_gig_tags {
                        guard let mergedNode = self.mergeNodes(localNode: localNode, latestNode: latestNode, exclude_gig_tags: exclude_gig_tags, editedTags: currentEditedTags) else {
                            print("Undo operation is not possible")
                            return latestNode.version
                        }
                        SyncLogger.shared.logStep("Nodes fetched and merged")
                        return try await updateNode(node: mergedNode, exclude_gig_tags: exclude_gig_tags)
                    }

                    var mergedNode = latestNode
                    mergedNode.changeset = localNode.changeset

                    if overrideConflicts {
                        // Workspace opted out of interactive conflict resolution: reinstate the
                        // pre-ConflictResolutionSheet behaviour — union the tags with every local
                        // value overriding the server, then retry on the fresh version.
                        for (key, value) in localNode.tags { mergedNode.tags[key] = value }
                        localNode = mergedNode
                        continue
                    }

                    let conflicts = currentEditedTags.compactMap { key, answeredValue -> ConflictingTag? in
                        guard let existingValue = latestNode.tags[key], existingValue != answeredValue else { return nil }
                        return ConflictingTag(key: key, existingValue: existingValue, answeredValue: answeredValue)
                    }

                    if conflicts.isEmpty {
                        for (key, value) in currentEditedTags { mergedNode.tags[key] = value }
                        localNode = mergedNode
                        continue // version moved but nothing we touched actually conflicts; retry on the new version
                    }

                    guard let resolvedTags = await promptForConflictResolution(
                        elementId: Int64(localNode.id), elementTypeName: elementTypeName, iconName: iconName,
                        editedTags: currentEditedTags, conflicts: conflicts
                    ) else {
                        throw SyncConflictError.cancelledByUser
                    }

                    currentEditedTags = resolvedTags
                    for (key, value) in resolvedTags { mergedNode.tags[key] = value }
                    localNode = mergedNode
                    // loop back and retry with the resolved tags on the latest version; if someone edits
                    // again while the user was deciding, this lands back here and re-prompts with fresh data
                } catch let error as APIError {
                    if case .deleted = error {
                        dbInstance.deleteChangesets(elementId: localNode.id)
                        dbInstance.deleteWay(id: localNode.id)
                        DispatchQueue.main.async {
                            QuestsPublisher.shared.elementDeleted.send(localNode.id)
                        }
                    }
                    throw error
                }
            }
        }
    }


    func mergeTagsForUndo(originalTags: [String : String], edited: [String : String], serverTags: [String : String]) -> [String : String]? {
        var resultTags: [String: String] = [:]
        print("mergeTagsForUndo originalTags \(originalTags) \n edited \(edited) \n serverTags \(serverTags)")
        for (key, value) in edited {
            if let orgValue = originalTags[key] {
                if let serverVal = serverTags[key] {
                    if orgValue != serverVal, value != serverVal {
                        return nil
                    }
                } else {
                    return nil
                }
            } else {
                if let serverVal = serverTags[key], value != serverVal {
                    return nil
                }
            }
        }
        
        let unionKeys = Set(originalTags.keys).union(Set(serverTags.keys))
        
        for key in unionKeys {
            if let serverValue = serverTags[key] {
                if let editValue = edited[key] {
                    if editValue == serverValue {
                        if let originalValue = originalTags[key]  {
                            resultTags[key] = originalValue
                            continue
                        }
                        continue
                    }
                }
                resultTags[key] = serverValue
            } else {
                resultTags.removeValue(forKey: key)
            }
        }
        resultTags.removeValue(forKey: "ext:gig_last_updated")
        resultTags.removeValue(forKey: "ext:gig_complete")
        print("mergeTagsForUndo resultTags \(resultTags)")
        return resultTags
    }
    
    func mergeWays(localWay: OSMWay, latestWay: OSMWay, exclude_gig_tags: Bool, editedTags: [String : String]) -> OSMWay? {
          var mergedWay = latestWay
        if exclude_gig_tags {
            if let resultTags = mergeTagsForUndo(originalTags: localWay.tags, edited: editedTags, serverTags: latestWay.tags) {
                mergedWay.tags = resultTags
            } else {
                return nil
            }
        } else {
            for (key, value) in localWay.tags {
                mergedWay.tags[key] = value
            }
        }
          mergedWay.changeset = localWay.changeset
          return mergedWay
      }
    
    func mergeNodes(localNode: OSMNode, latestNode: OSMNode, exclude_gig_tags: Bool, editedTags: [String : String]) -> OSMNode? {
        var mergedNode = latestNode
        if exclude_gig_tags {
            if let resultTags = mergeTagsForUndo(originalTags: localNode.tags, edited: editedTags, serverTags: latestNode.tags) {
                mergedNode.tags = resultTags
            } else {
                return nil
            }
        } else {
            for (key, value) in localNode.tags {
                mergedNode.tags[key] = value
            }
        }
        mergedNode.changeset = localNode.changeset
        return mergedNode
    }
    
    func fetchWay21(wayId: String, completion: @escaping (Result<OSMWay, Error>) -> Void) {
        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
            let error = NSError(domain: "FetchWayError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Missing workspace ID"])
            completion(.failure(error))
            return
        }
        
        ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID, wayId), setupType: .osm, modelType: OSMWayResponse.self) { result in
            switch result {
            case .success(let osmwayResponse):
                if let osmway = osmwayResponse.elements.first {
                    completion(.success(osmway))
                } else {
                    let error = NSError(domain: "FetchWayError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No OSM way found"])
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func fetchway2(wayId: String) async throws -> OSMWay {
        let workspaceID = KeychainManager.load(key: "workspaceID")
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID!, wayId), setupType: .osm, modelType: OSMWayResponse.self) { result in
                switch result {
                case .success(let osmwayResponse):
                    if let osmway = osmwayResponse.elements.first {
                        continuation.resume(returning: osmway)
                    } else {
                        continuation.resume(throwing: NSError(domain: "OSM", code: 404, userInfo: [NSLocalizedDescriptionKey: "Way not found"]))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchNode2(nodeId: String) async throws -> OSMNode {
        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
            throw NSError(domain: "No WorkspaceID", code: 0, userInfo: nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(
                to: .fetchLatestNode(workspaceID, nodeId),
                setupType: .osm,
                modelType: OSMNodeResponse.self
            ) { result in
                switch result {
                case .success(let osNodeResponse):
                    if let osmnode = osNodeResponse.elements.first {
                        continuation.resume(returning: osmnode)
                    } else {
                        continuation.resume(throwing: NSError(domain: "No Node Found", code: 0, userInfo: nil))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Fetches the latest tags and edit timestamp for an element from OSM and
    /// refreshes the local cache with them. Returns nil if the fetch fails
    /// (offline/error) so callers can fall back to the existing local-first flow.
    func fetchLatestTags(id: Int64, isWay: Bool) async -> (tags: [String: String], timestamp: Date)? {
        do {
            if isWay {
                let way = try await fetchway2(wayId: "\(id)")
                dbInstance.saveOSMElements([way])
                return (way.tags, way.timestamp)
            } else {
                let node = try await fetchNode2(nodeId: "\(id)")
                dbInstance.saveOSMElements([node])
                return (node.tags, node.timestamp)
            }
        } catch {
            print("fetchLatestTags failed (offline or error): \(error)")
            return nil
        }
    }

    /**
            Syncs the node along with the updated
     */
    @MainActor
    func syncNode(node: OSMNode, exclude_gig_tags: Bool, editedTags: [String : String], elementTypeName: String = "Element", iconName: String = "notes") async throws -> (result:Bool, version: Int) {
        var localNode = node

        SyncLogger.shared.logStep("Open Changeset")

        // Step 1: Open changeset
        do {
            let changesetID = try await openChangeset()

            print("Opened changeset \(changesetID)")
            localNode.changeset = changesetID

            //Step 2: Update Node
            let newVersion = try await updateNode2(node: localNode, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags, elementTypeName: elementTypeName, iconName: iconName)
            localNode.version = newVersion
            _ = self.dbInstance.updateNodeVersion(nodeId: String(localNode.id), version: newVersion)

            //Stepp 3:Close changeset
            SyncLogger.shared.logStep("Close Changeset")
            let result = try await closeChangeset(id: String(changesetID))
            return (result, newVersion)

        } catch SyncConflictError.cancelledByUser {
            print("User declined conflict resolution for node \(localNode.id); leaving unsynced")
            return (false, localNode.version)
        } catch {
            print("Failed to open changeset:", error.localizedDescription)
            throw error
        }
    }
        
    func createNode(node: OSMNode) async throws -> CreatedElementResult {
        var localNode = node

        do {
            let changesetID = try await openChangeset()

            localNode.changeset = changesetID

            let created = try await uploadNode(node: localNode)
            _ = try await closeChangeset(id: String(changesetID))
            return created
        } catch {
            print("createNode error: \(error)")
            throw error;
        }
    }

    /// Permanently deletes a node from the OSM server — used only to undo a
    /// just-created feature (see `AddFeatureView`/`StoredChangeset.isCreatedElement`).
    /// Never used to revert a tag edit on a pre-existing element; that stays a
    /// `<modify>` via `syncNode`/`updateNode`.
    func deleteNode(node: OSMNode) async throws -> Bool {
        var localNode = node

        do {
            let changesetID = try await openChangeset()
            localNode.changeset = changesetID

            let deleteBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + localNode.toDeletePayload() + "</osmChange>"
            guard let bodyData = deleteBody.data(using: .utf8) else {
                throw APIError.decodingFailed("Invalid Node Body")
            }
            let workspaceId = KeychainManager.load(key: "workspaceID")
            guard let accessToken = KeychainManager.load(key: "accessToken") else {
                throw APIError.unauthorized
            }

            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                ApiManager.shared.performRequest(to: .uploadChangeset(accessToken, "\(changesetID)", workspaceId ?? "", bodyData), setupType: .osm, modelType: String.self, useJSON: false) { result in
                    switch result {
                    case .success(let response):
                        continuation.resume(returning: response)
                    case .failure(let failure):
                        continuation.resume(throwing: failure)
                    }
                }
            }

            return try await closeChangeset(id: String(changesetID))
        } catch {
            print("deleteNode error: \(error)")
            throw error
        }
    }

    @MainActor
    func syncWay(way: OSMWay, exclude_gig_tags: Bool, editedTags: [String : String], elementTypeName: String = "Element", iconName: String = "notes") async throws -> (result: Bool, version: Int) {
        var localWay = way

        do {

            let changesetID = try await openChangeset()

            localWay.changeset = changesetID

            let newVersion = try await updateWay2(way: localWay, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags, elementTypeName: elementTypeName, iconName: iconName)

            localWay.version = newVersion

            _ = self.dbInstance.updateWayVersion(wayId: String(localWay.id), version: newVersion)
            let result = try await closeChangeset(id: String(changesetID))
            return  (result, newVersion)

        } catch SyncConflictError.cancelledByUser {
            print("User declined conflict resolution for way \(localWay.id); leaving unsynced")
            return (false, localWay.version)
        } catch {
            throw error
        }
    }


}

// POSM has two components
// Web ROR (ruby on rails) component -> handles /create,/modify -> No workspaces implementation POSM token
// CGIMap component -> /changeset (create,upload,close) -> Workspaces + auth token integration-> TDEI token + workspace

