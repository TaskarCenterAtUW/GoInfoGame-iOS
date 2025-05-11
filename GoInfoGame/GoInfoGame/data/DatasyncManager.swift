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
    
    func syncDataToOSM(exclude_gig_tags: Bool, completionHandler: @escaping (Result<Bool, APIError>)  -> Void) {
        barrierQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let semaphore = DispatchSemaphore(value: 0)
            
            Task.detached(priority: .userInitiated) {
                do {
                    let isSynced = try await self.syncData(exclude_gig_tags: exclude_gig_tags)
                    
                    print("Sync finished")
                    if isSynced {
                        print("Sync successful")
                        DispatchQueue.main.async {
                            completionHandler(.success(true)) // Success
                        }
                    } else {
                        print("Sync failed")
                        DispatchQueue.main.async {
                            completionHandler(.failure(APIError.custom("Sync failed. Please try again."))) // Failure
                        }
                    }
                } catch {
                    print("Sync failed: \(error)")
                    DispatchQueue.main.async {
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
    @MainActor
    func syncData(exclude_gig_tags: Bool = false) async throws -> Bool {
        print("🔄 Starting sync...")

        let changesets = dbInstance.getChangesets()
        print("Found \(changesets.count) changesets for synced=false")

        // Filter changesets that have valid edited versions
        let validChangesets = changesets.filter {
            let intId = Int($0.elementId) ?? -1
            switch $0.elementType {
            case .way:
                let exists = self.dbInstance.getWay(id: intId, version: .original) != nil
                if !exists {
                    print("⚠️ Edited way not found for ID: \(intId)")
                }
                return exists
            case .node:
                let exists = self.dbInstance.getNode(id: intId, version: .original) != nil
                if !exists {
                    print("⚠️ Edited node not found for ID: \(intId)")
                }
                return exists
            default:
                return false
            }
        }

        print("📦 Found \(validChangesets.count) unsynced changesets with valid edits")

        var nodesToSync: [String: StoredChangeset] = [:]
        var waysToSync: [String: StoredChangeset] = [:]

        for cs in validChangesets {
            let intId = Int(cs.elementId) ?? -1
            if cs.elementType == .node,
               let node = dbInstance.getNode(id: intId, version: .original) {
                nodesToSync[cs.id] = cs
            } else if cs.elementType == .way,
                      let way = dbInstance.getWay(id: intId, version: .original) {
                waysToSync[cs.id] = cs
            }
        }

        var syncSuccess = true

        if nodesToSync.isEmpty && waysToSync.isEmpty {
            print("✅ No edited elements found to sync")
            return true
        }

        for (key, node) in nodesToSync {
            print("📤 Syncing node ID: \(node.id)")
            let payload = node.asOSMNode()
            do {
                let status = try await syncNode(node: payload, exclude_gig_tags: exclude_gig_tags, editedTags: node.tags.toDictionary())
                if status.result {
                    DispatchQueue.main.async {
                        self.dbInstance.assignChangesetId(obj: key, changesetId: 0, updatedVersion: status.version)
                    }
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
            print("📤 Syncing way ID: \(way.id)")
            let payload = way.asOSMWay()
            do {
                let status = try await syncWay(way: payload, exclude_gig_tags: exclude_gig_tags, editedTags: way.tags.toDictionary())
                if status.result {
                    DispatchQueue.main.async {
                        self.dbInstance.assignChangesetId(obj: key, changesetId: 0, updatedVersion: status.version)
                    }
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
        guard let existing = DatabaseConnector.shared.getWay(id: newWay.id, version: .original) else {
            DatabaseConnector.shared.saveOSMElements([newWay])
            return
        }

        if newWay.version > existing.version {
            DatabaseConnector.shared.saveOSMElements([newWay])
        }
    }
    
    func refreshOriginalNodeIfNewer(_ newNode: OSMNode) {
        guard let existing = DatabaseConnector.shared.getNode(id: newNode.id, version: .original) else {
            DatabaseConnector.shared.saveOSMElements([newNode])
            return
        }

        if newNode.version > existing.version {
            DatabaseConnector.shared.saveOSMElements([newNode])
        }
    }

    func syncDataDummy() async  {
        
        let changesets = dbInstance.getChangesets()
        print("Starting to sync data")
        for changeset in changesets {
            let result = await dummyTask()
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
        
        guard let accessToken = KeychainManager.loadSessionValue("accessToken")else {
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
        
        guard let accessToken = KeychainManager.loadSessionValue("accessToken") else {
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
        let wayId = "\(localWay.id)"
        let newVersion = way.version + 1
        print("Uploading changeset \(changesetUploadBody)")
        guard let accessToken = KeychainManager.loadSessionValue("accessToken")else {
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
                    var tags = localWay.tags
                    // The gig tags are not added into the db when pushing directly
                    // Adding them forcibly here.
                    if (!exclude_gig_tags) {
                        let gig_internal_tags = localWay.fetchInternalGigTags()
                        gig_internal_tags.forEach { (key: String, value: String) in
                            tags[key] = value
                        }
                    }
                    DispatchQueue.main.async {
                        _ = DatabaseConnector.shared.addWayTags(id: id, tags: tags, version: newVersion)
                    }
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
        var localNode = node
        let nodeBodyString = localNode.toPayload(exclude_gig_tags: exclude_gig_tags)
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + nodeBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            throw NSError(domain: "Invalid Node Body", code: 0, userInfo: nil)
        }
        print("Uploading changeset \(changesetUploadBody)")

        let newVersion = localNode.version + 1

        guard let accessToken = KeychainManager.loadSessionValue("accessToken") else {
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
                    
                    // Gig tags are not added to DB when pushing changes
                    // those are added manually here
                    if (!exclude_gig_tags) {
                        let gig_internal_tags = updatedNode.fetchInternalGigTags()
                        gig_internal_tags.forEach { (key: String, value: String) in
                            updatedNode.tags[key] = value
                        }
                    }
                    SyncLogger.shared.logStep("Node Updated ----\(updatedNode.tags)")
                    DispatchQueue.main.async {
                        
                        _ = DatabaseConnector.shared.addNodeTags(id: updatedNode.id, tags: updatedNode.tags, version: newVersion)
                    }
                    continuation.resume(returning: newVersion)
                case .failure(let error):
                    print(error)
                    SyncLogger.shared.logStep("❌ Node updation failed ----\(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func uploadNode(node: OSMNode, exclude_gig_tags: Bool = false) async throws -> Bool {
        var localNode = node
        let nodeBodyString = localNode.toCreatePayload(exclude_gig_tags: exclude_gig_tags)
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + nodeBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            throw APIError.decodingFailed("Invalid Node Body")
        }

        guard let accessToken = KeychainManager.loadSessionValue("accessToken") else {
            throw APIError.unauthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .uploadChangeset(accessToken, "\(node.changeset)", workspaceId ?? "", nodeBody), setupType: .osm, modelType: String.self, useJSON: false) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    func updateWay2(way: OSMWay, exclude_gig_tags: Bool, editedTags: [String : String]) async throws -> Int {
        var localWay = way
        let wayId = "\(localWay.id)"
        var updatedResult: Int = -1
        do {
            updatedResult = try await updateWay(way: localWay, exclude_gig_tags: exclude_gig_tags)
            return updatedResult
        } catch let error as APIError {
            switch error {
            case .conflict:
                let updatedWay = try await fetchway2(wayId: wayId)
                if let mergedWay = self.mergeWays(localWay: localWay, latestWay: updatedWay, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags) {
                    print("Local way")
                    print(localWay)
                    print("Merged way")
                    print(mergedWay)
                    return try await updateWay(way: mergedWay, exclude_gig_tags: exclude_gig_tags)
                } else {
                    print("Undo operation is not possible")
                    return updatedWay.version
                }
                
            default:
                throw error
            }
        }
    }

    func updateNode2(node: OSMNode, exclude_gig_tags: Bool, editedTags: [String : String]) async throws -> Int {
        var localNode = node
        
        let nodeId = "\(localNode.id)"
        SyncLogger.shared.logStep("Updating node \(nodeId) under new changeset")

        var updatedResult: Int = -1
        do {
             updatedResult = try await updateNode(node: localNode, exclude_gig_tags: exclude_gig_tags)
            return updatedResult
            
        } catch let error as APIError {
            switch error {
            case .conflict:
                SyncLogger.shared.logStep("Fetching node due to conflict")
                let fetchedResult = try await fetchNode2(nodeId: "\(localNode.id)")
                
                if let mergedNode = self.mergeNodes(localNode: localNode, latestNode: fetchedResult, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags) {
                    print("Local Node:")
                    print(localNode)
                    print("Merged Node:")
                    print(mergedNode)
                    SyncLogger.shared.logStep("Nodes fetched and merged")
                    return try await updateNode(node: mergedNode, exclude_gig_tags: exclude_gig_tags)
                } else {
                    print("Undo operation is not possible")
                    // update the original node with the server node.
                    // FIXME: this is not done. Need to do something.
                    return fetchedResult.version
                }
                
            default:
                throw error
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

    /**
            Syncs the node along with the updated
     */
    @MainActor
    func syncNode(node: OSMNode, exclude_gig_tags: Bool, editedTags: [String : String]) async throws -> (result:Bool, version: Int) {
        var localNode = node
        
        SyncLogger.shared.logStep("Open Changeset")
        
        // Step 1: Open changeset
        do {
            let changesetID = try await openChangeset()
            
            print("Opened changeset \(changesetID)")
            localNode.changeset = changesetID
            
            //Step 2: Update Node
            let newVersion = try await updateNode2(node: localNode, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags)
            localNode.version = newVersion
            DispatchQueue.main.async {
                self.dbInstance.updateNodeVersion(nodeId: String(localNode.id), version: newVersion)
            }
            
            //Stepp 3:Close changeset
            SyncLogger.shared.logStep("Close Changeset")
            let result = try await closeChangeset(id: String(changesetID))
            return (result, newVersion)
        
        } catch {
            print("Failed to open changeset:", error.localizedDescription)
            throw error
        }
    }
        
    func createNode(node: OSMNode) async throws -> Bool {
        var localNode = node

        do {
            let changesetID = try await openChangeset()

            localNode.changeset = changesetID

            let uploadResult = try await uploadNode(node: localNode)

            if uploadResult {
                return try await closeChangeset(id: String(changesetID))
            } else {
                throw NSError(domain: "Upload Failed", code: 0, userInfo: nil)
            }
        } catch {
            print("createNode error: \(error)")
            throw error;
        }
    }
    
    @MainActor
    func syncWay(way: OSMWay, exclude_gig_tags: Bool, editedTags: [String : String]) async throws -> (result: Bool, version: Int) {
        var localWay = way
        
        do {
            
            let changesetID = try await openChangeset()
            
            localWay.changeset = changesetID
            
            let newVersion = try await updateWay2(way: localWay, exclude_gig_tags: exclude_gig_tags, editedTags: editedTags)
            
            localWay.version = newVersion
            
            DispatchQueue.main.async {
                self.dbInstance.updateWayVersion(wayId: String(localWay.id), version: newVersion)
            }
            let result = try await closeChangeset(id: String(changesetID))
            return  (result, newVersion)
            
        } catch {
            throw error
        }
    }


}

// POSM has two components
// Web ROR (ruby on rails) component -> handles /create,/modify -> No workspaces implementation POSM token
// CGIMap component -> /changeset (create,upload,close) -> Workspaces + auth token integration-> TDEI token + workspace

