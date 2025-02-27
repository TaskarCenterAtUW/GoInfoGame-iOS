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
    
    private let osmConnection = OSMConnection(config: OSMConfig.testPOSM, currentChangesetId: nil)
    
    func syncDataToOSM(completionHandler: @escaping (Bool) -> Void) {
        Task {
            do {
                try await syncData() // Assuming syncData() can throw
                DispatchQueue.main.async {
                    completionHandler(true) // Success
                }
            } catch {
                print("Sync failed: \(error)")
                DispatchQueue.main.async {
                    completionHandler(false) // Failure
                }
            }
        }
    }
    
    /// *** Terminating app due to uncaught exception 'RLMException', reason: 'Realm accessed from incorrect thread.'
    ///  To fix the above error added @mainActor
    @MainActor
    func syncData() async -> Bool {
        if isSynching {
            print("Already syncing")
            return false
        } else {
            isSynching = true
        }

        let changesets = dbInstance.getChangesets()
        print("Starting to sync data")
        
        var nodesToSync: [String: StoredNode] = [:]
        var waysToSync: [String: StoredWay] = [:]
        
        for changeset in changesets {
            if changeset.elementType == .node, let node = dbInstance.getNode(id: changeset.elementId) {
                nodesToSync[changeset.id] = node
            } else if changeset.elementType == .way, let way = dbInstance.getWay(id: changeset.elementId) {
                waysToSync[changeset.id] = way
            }
        }

        var syncSuccess = true

        for (key, node) in nodesToSync {
            var payload = node.asOSMNode()
            do {
                let isFinished = try await syncNode(node: payload)
                if isFinished {
                    DispatchQueue.main.async {
                        self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                    }
                    return isFinished
                } else {
                    syncSuccess = false
                    return false
                }
                print("Sync finished for node: \(isFinished)")
            } catch {
                print("Failed to sync node: \(error.localizedDescription)")
                syncSuccess = false
                return false
            }
        }

        for (key, way) in waysToSync {
            var payload = way.asOSMWay()
            do {
                let isFinished = try await syncWay(way: payload)
                if isFinished {
                    DispatchQueue.main.async {
                        self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                    }
                    return isFinished
                } else {
                    syncSuccess = false
                    return false
                }
                print("Sync finished for way: \(isFinished)")
            } catch {
                print("Failed to sync way: \(error.localizedDescription)")
                syncSuccess = false
                return false
            }
        }
        isSynching = false
        return syncSuccess
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
    
    func openChangeset() async throws -> Int {
        var versionNumber = ""
        var buildNumber = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionNumber = version
            buildNumber = build
        }
        
        let createdBy = "\(versionNumber)(\(buildNumber))"
        let osmPayloadString = OSMChangesetPayload(createdByTag: createdBy).toPayload()
        let osmPayload = osmPayloadString.data(using: .utf8)
        let workspaceId = KeychainManager.load(key: "workspaceID")
        
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
               throw NSError(domain: "NoAccessToken", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Access Token found"])
           }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(to: .openChangesets(accessToken, workspaceId ?? "", osmPayload!),setupType: .osm, modelType: Int.self) { result in
                switch result {
                case .success(let changesetID):
                    continuation.resume(returning: changesetID)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }


    ///////////////
//    public func openChangeSet(createdByTag: String, _ completion: @escaping((Result<Int,Error>)->Void)) {
//        //TODO: Write errors when not authenticated and if there is already an open changeset with same user
//        let urlString1 = self.baseUrl.appending("changeset/create")
//        let urlString = "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6/changeset/create"
//        guard let url = URL(string: urlString) else {
//            print("Invalid URL given")
//            return
//        }
//       // let workspaceID = KeychainManager.load(key: "workspaceID")
//        BaseNetworkManager.shared.addOrSetHeaders(header: "Authorization", value: "Bearer \(accessToken!)")
//        BaseNetworkManager.shared.postData(url: url,method: "PUT" ,body: OSMChangesetPayload(createdByTag: createdByTag)) { (result: Result<Int,Error>) in
//            switch result {
//            case .success(let changesetID):
//                print("CHANGESET ID ===>\(changesetID)")
//                self.currentChangesetId = changesetID
//                
//            case .failure(let error):
//                print(error)
//            }
//            completion(result)
//        }
//    }
    //////////
    
//    func closeChangeset(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
//        print("Closing changeset \(id)")
//        osmConnection.closeChangeSet(id: id) { result in
//            completion(result) // Simply pass along the result
//        }
//    }
    
    func closeChangeset(id: String) async throws -> Bool {
        print("Closing changeset \(id)")
        
        return try await withCheckedThrowingContinuation { continuation in
            osmConnection.closeChangeSet(id: id) { result in
                switch result {
                case .success(let success):
                    continuation.resume(returning: success)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    
    // utility function to act as substitute for osmConnection functions
    func updateWay(way: OSMWay) async throws -> Int {
        var localWay = way
        let wayBodyString = localWay.toPayload()
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + wayBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")
        let wayBody = changesetUploadBody.data(using: .utf8)
        let wayId = "\(localWay.id)"
        let newVersion = way.version + 1

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
                    continuation.resume(returning: newVersion)

                case .failure(let error):
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
  
    // utility function to act as substitute for osmConnection functions
    func updateNode(node: OSMNode) async throws -> Int {
        var localNode = node
        let nodeBodyString = localNode.toPayload()
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
                    continuation.resume(returning: newVersion)
                case .failure(let error):
                    print(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func uploadNode(node: OSMNode) async throws -> Bool {
        var localNode = node
        let nodeBodyString = localNode.toCreatePayload()
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">\(nodeBodyString)</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            throw APIError.decodingError(NSError(domain: "Invalid Node Data", code: 0, userInfo: nil))
        }

        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            throw APIError.unknown(NSError(domain: "No AccessToken", code: 0, userInfo: nil))
        }

        do {
            let result: String = try await ApiManager.shared.performRequestA(
                to: .uploadChangeset(accessToken, "\(node.changeset)", workspaceId ?? "", nodeBody),
                setupType: .osm,
                modelType: String.self,
                useJSON: false
            )
            return true;
        } catch {
            print("Upload failed: \(error)")
            throw error;
        }
    }

    
//    func uploadNode(node: OSMNode) async throws -> Bool {
//        var localNode = node
//        let nodeBodyString = localNode.toCreatePayload()
//        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">\(nodeBodyString)</osmChange>"
//        let workspaceId = KeychainManager.load(key: "workspaceID")
//
//        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
//            throw NSError(domain: "Invalid Node Data", code: 0, userInfo: nil)
//        }
//
//        guard let accessToken = KeychainManager.load(key: "accessToken") else {
//            throw NSError(domain: "No AccessToken", code: 0, userInfo: nil)
//        }
//
//        return try await withCheckedThrowingContinuation { continuation in
//            let workItem = DispatchWorkItem {
//                continuation.resume(throwing: NSError(domain: "Request Timeout", code: -999, userInfo: nil))
//            }
//
//            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
//
//            ApiManager.shared.performRequest(
//                to: .uploadChangeset(accessToken, "\(node.changeset)", workspaceId ?? "", nodeBody),
//                setupType: .osm,
//                modelType: String.self,
//                useJSON: false
//            ) { result in
//                workItem.cancel() // Cancel the DispatchWorkItem if the request completes
//
//                switch result {
//                case .success:
//                    continuation.resume(returning: true)
//                case .failure(let error):
//                    print("uploadNode error: \(error)")
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
    
    func updateWay2(way: OSMWay) async throws -> Int {
        var localWay = way
        let wayId = "\(localWay.id)"
        var updatedResult: Int = -1
        do {
             updatedResult = try await updateWay(way: localWay)
            return updatedResult
        } catch {
            if (error as NSError).code == 409 {
                let updatedWay = try await fetchway2(wayId: wayId)
                var mergedWay = self.mergeWays(localWay: localWay, latestWay: updatedWay)
                print("Local way")
                print(localWay)
                print("Merged way")
                print(mergedWay)
                
                return try await updateWay(way: mergedWay)
    
            } else {
               return updatedResult
            }
        }
    }

    func updateNode2(node: OSMNode) async throws -> Int {
        var localNode = node
        
        let nodeId = "\(localNode.id)"
        print("Updating node \(nodeId) under new changeset")
        var updatedResult: Int = -1
        do {
             updatedResult = try await updateNode(node: localNode)
            return updatedResult
            
        } catch {
            if (error as NSError).code == 409 {
                let fetchedResult = try await fetchNode2(nodeId: "\(localNode.id)")
                var mergedNode = self.mergeNodes(localNode: localNode, latestNode: fetchedResult)
                print("Local Node:")
                print(localNode)
                print("Merged Node:")
                print(mergedNode)
                return try await updateNode(node: mergedNode)
            } else {
                return updatedResult
            }
        }
    }


    func mergeWays(localWay: OSMWay, latestWay: OSMWay) -> OSMWay {
          var mergedWay = latestWay
          for (key, value) in localWay.tags {
              mergedWay.tags[key] = value
          }
          mergedWay.changeset = localWay.changeset
          return mergedWay
      }
    
    func mergeNodes(localNode: OSMNode, latestNode: OSMNode) -> OSMNode {
        var mergedNode = latestNode
        for (key, value) in localNode.tags {
            mergedNode.tags[key] = value
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

//    func fetchWay2(wayId: String, completion: @escaping (Result<OSMWay, Error>) -> Void) {
//        let workspaceID = KeychainManager.load(key: "workspaceID")
//        ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID!, wayId), setupType: .osm, modelType: OSMWayResponse.self) { result in
//            switch result {
//            case .success(let osmwayResponse):
//                if let osmway = osmwayResponse.elements.first {
//                    completion(.success(osmway))
//                } else {
//                    completion(.failure(NSError(domain: "OSM", code: 404, userInfo: [NSLocalizedDescriptionKey: "Way not found"])))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }

    
//    func fetchNode2(nodeId: String, completion: @escaping (Result<OSMNode, Error>) -> Void) {
//        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
//            completion(.failure(NSError(domain: "No WorkspaceID", code: 0, userInfo: nil)))
//            return
//        }
//        
//        ApiManager.shared.performRequest(
//            to: .fetchLatestWay(workspaceID, nodeId),
//            setupType: .osm,
//            modelType: OSMNodeResponse.self
//        ) { result in
//            switch result {
//            case .success(let osNodeResponse):
//                if let osmnode = osNodeResponse.elements.first {
//                    completion(.success(osmnode))
//                } else {
//                    completion(.failure(NSError(domain: "No Node Found", code: 0, userInfo: nil)))
//                }
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
    func fetchNode2(nodeId: String) async throws -> OSMNode {
        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
            throw NSError(domain: "No WorkspaceID", code: 0, userInfo: nil)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            ApiManager.shared.performRequest(
                to: .fetchLatestWay(workspaceID, nodeId),
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
    func syncNode(node: OSMNode) async throws -> Bool {
        var localNode = node
        
        // Step 1: Open changeset
        do {
            let changesetID = try await openChangeset()
            
            print("Opened changeset \(changesetID)")
            localNode.changeset = changesetID
            
            //Step 2: Update Node
            let newVersion = try await updateNode2(node: localNode)
            localNode.version = newVersion
            DispatchQueue.main.async {
                self.dbInstance.updateNodeVersion(nodeId: String(localNode.id), version: newVersion)
            }
            
            //Stepp 3:Close changeset
           return try await closeChangeset(id: String(changesetID))
        
        } catch {
            print("Failed to open changeset:", error.localizedDescription)
            return false
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








    
  //  @MainActor
//    func createNode(node: inout OSMNode) async -> Result<Bool,Error> {
//        do {
//            //open changeset
//            let changesetId = try await openChangeset().get()
//            //create node/upload changeset
//            node.changeset = changesetId
//            let uploadNodeResult = await uploadNode(node: &node)
//            
//            switch uploadNodeResult {
//            case .success:
//                let _ = try await closeChangeset(id: String(changesetId)).get()
//                return .success(true)
//            case .failure(let failure):
//                print(failure)
//                return .failure(failure)
//            }
//        } catch (let error) {
//            print(error)
//            return .failure(error)
//        }
//    }
    
    @MainActor
    func syncWay(way: OSMWay) async throws -> Bool {
        var localWay = way
        
        do {
            
            let changesetID = try await openChangeset()
            
            localWay.changeset = changesetID
            
            let newVersion = try await updateWay2(way: localWay)
            
            localWay.version = newVersion
            
            DispatchQueue.main.async {
                self.dbInstance.updateWayVersion(wayId: String(localWay.id), version: newVersion)
            }
            
            return try await closeChangeset(id: String(changesetID))
            
        } catch {
            return false
        }
    }


}

// POSM has two components
// Web ROR (ruby on rails) component -> handles /create,/modify -> No workspaces implementation POSM token
// CGIMap component -> /changeset (create,upload,close) -> Workspaces + auth token integration-> TDEI token + workspace

