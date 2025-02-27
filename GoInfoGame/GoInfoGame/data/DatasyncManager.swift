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
                let isFinished = try await withCheckedThrowingContinuation { continuation in
                    syncNode(node: &payload) { result in
                        switch result {
                        case .success(let isFinished):
                            DispatchQueue.main.async {
                                self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                            }
                            continuation.resume(returning: isFinished)
                        case .failure:
                            syncSuccess = false
                            continuation.resume(returning: false)
                        }
                    }
                }
                print("Sync finished for node: \(isFinished)")
            } catch {
                print("Failed to sync node: \(error.localizedDescription)")
                syncSuccess = false
            }
        }

        for (key, way) in waysToSync {
            var payload = way.asOSMWay()
            do {
                let isFinished = try await withCheckedThrowingContinuation { continuation in
                    syncWay(way: &payload) { result in
                        switch result {
                        case .success(let isFinished):
                            DispatchQueue.main.async {
                                self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                            }
                            continuation.resume(returning: isFinished)
                        case .failure:
                            syncSuccess = false
                            continuation.resume(returning: false)
                        }
                    }
                }
                print("Sync finished for way: \(isFinished)")
            } catch {
                print("Failed to sync way: \(error.localizedDescription)")
                syncSuccess = false
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
    
    func openChangeset(completion: @escaping (Result<Int, Error>) -> Void) {
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
            completion(.failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            return
        }
        
        ApiManager.shared.performRequest(to: .openChangesets(accessToken, workspaceId ?? "", osmPayload!), setupType: .osm, modelType: Int.self) { result in
            switch result {
            case .success(let changesetID):
                print("ChangesetID is ---\(changesetID)")
                completion(.success(changesetID))
            case .failure(let error):
                print(error)
                completion(.failure(error))
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
    
    func closeChangeset(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        print("Closing changeset \(id)")
        osmConnection.closeChangeSet(id: id) { result in
            completion(result) // Simply pass along the result
        }
    }


    // utility function to act as substitute for osmConnection functions
    func updateWay(way: inout OSMWay, completion: @escaping (Result<Int, Error>) -> Void) {
        var localWay = way
        let wayBodyString = localWay.toPayload()
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + wayBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")
        let wayBody = changesetUploadBody.data(using: .utf8)
        let wayId = "\(localWay.id)"
        let newVersion = way.version + 1

        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            completion(.failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            return
        }

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
                completion(.success(newVersion))

            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }

    
    // utility function to act as substitute for osmConnection functions
    func updateNode(node: inout OSMNode, completion: @escaping (Result<Int, Error>) -> Void) {
        var localNode = node  // ✅ Create a copy of `node`
        let nodeBodyString = localNode.toPayload()
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">" + nodeBodyString + "</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")

        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Invalid Node Body", code: 0, userInfo: nil)))
            return
        }
        print("Uploading changeset \(changesetUploadBody)")

        let newVersion = localNode.version + 1

        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            completion(.failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            return
        }

        ApiManager.shared.performRequest(
            to: .uploadChangeset(accessToken, "\(localNode.changeset)", workspaceId ?? "", nodeBody),
            setupType: .osm,
            modelType: String.self,
            useJSON: false
        ) { result in
            switch result {
            case .success:
                var updatedNode = localNode  // ✅ Create another copy for safety
                updatedNode.tags.forEach { (key: String, value: String) in
                    updatedNode.tags[key] = value
                }
                updatedNode.version = newVersion  // ✅ Update version
                completion(.success(newVersion))

            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }


    
    func uploadNode(node: inout OSMNode, completion: @escaping (Result<Bool, Error>) -> Void) {
        var localNode = node
        let nodeBodyString = localNode.toCreatePayload()
        let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">\(nodeBodyString)</osmChange>"
        let workspaceId = KeychainManager.load(key: "workspaceID")
        
        guard let nodeBody = changesetUploadBody.data(using: .utf8) else {
            completion(.failure(NSError(domain: "Invalid Node Data", code: 0, userInfo: nil)))
            return
        }
        
        guard let accessToken = KeychainManager.load(key: "accessToken") else {
            completion(.failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            return
        }
        
        ApiManager.shared.performRequest(
            to: .uploadChangeset(accessToken, "\(node.changeset)", workspaceId ?? "", nodeBody),
            setupType: .osm,
            modelType: String.self,
            useJSON: false
        ) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }

    
    func updateWay2(way: inout OSMWay, completion: @escaping (Result<Int, Error>) -> Void) {
        var localWay = way  // ✅ Create a copy of `way`
        
        self.updateWay(way: &localWay) { updatedResult in
            let wayId = "\(localWay.id)"
            
            switch updatedResult {
            case .success:
                completion(updatedResult)
                
            case .failure(let error):
                // Check for 409 Conflict Error
                if (error as NSError).code == 409 {
                    self.fetchWay2(wayId: wayId) { fetchResult in
                        switch fetchResult {
                        case .success(let updatedWay):
                            var mergedWay = self.mergeWays(localWay: localWay, latestWay: updatedWay)
                            print("Local way")
                            print(localWay)
                            print("Merged way")
                            print(mergedWay)

                            self.updateWay(way: &mergedWay) { mergeResult in
                                completion(mergeResult)
                            }

                        case .failure(let fetchError):
                            completion(.failure(fetchError))
                        }
                    }
                    
                } else {
                    completion(updatedResult)
                }
            }
        }
    }


    
    func updateNode2(node: inout OSMNode, completion: @escaping (Result<Int, Error>) -> Void) {
        var localNode = node  // ✅ Create a local copy of `node`
        
        self.updateNode(node: &localNode) { updatedResult in
            let nodeId = "\(localNode.id)"  // ✅ Use localNode instead of node
            print("Updating node \(nodeId) under new changeset")
            switch updatedResult {
            case .success:
                completion(updatedResult)

            case .failure(let error):
                if (error as NSError).code == 409 {
                    self.fetchNode2(nodeId: nodeId) { fetchResult in
                        switch fetchResult {
                        case .success(let updatedNode):
                            var mergedNode = self.mergeNodes(localNode: localNode, latestNode: updatedNode)
                            print("Local Node:")
                            print(localNode)
                            print("Merged Node:")
                            print(mergedNode)

                            self.updateNode(node: &mergedNode) { mergeResult in
                                completion(mergeResult)
                            }

                        case .failure(let fetchError):
                            completion(.failure(fetchError))
                        }
                    }
                } else {
                    completion(updatedResult)
                }
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


    
    func fetchWay2(wayId: String, completion: @escaping (Result<OSMWay, Error>) -> Void) {
        let workspaceID = KeychainManager.load(key: "workspaceID")
        ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID!, wayId), setupType: .osm, modelType: OSMWayResponse.self) { result in
            switch result {
            case .success(let osmwayResponse):
                if let osmway = osmwayResponse.elements.first {
                    completion(.success(osmway))
                } else {
                    completion(.failure(NSError(domain: "OSM", code: 404, userInfo: [NSLocalizedDescriptionKey: "Way not found"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    func fetchNode2(nodeId: String, completion: @escaping (Result<OSMNode, Error>) -> Void) {
        guard let workspaceID = KeychainManager.load(key: "workspaceID") else {
            completion(.failure(NSError(domain: "No WorkspaceID", code: 0, userInfo: nil)))
            return
        }
        
        ApiManager.shared.performRequest(
            to: .fetchLatestWay(workspaceID, nodeId),
            setupType: .osm,
            modelType: OSMNodeResponse.self
        ) { result in
            switch result {
            case .success(let osNodeResponse):
                if let osmnode = osNodeResponse.elements.first {
                    completion(.success(osmnode))
                } else {
                    completion(.failure(NSError(domain: "No Node Found", code: 0, userInfo: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

   
    /**
            Syncs the node along with the updated
     */
    @MainActor
    func syncNode(node: inout OSMNode, completion: @escaping (Result<Bool, Error>) -> Void) {
        var localNode = node  // ✅ Create a local copy of `node`
        
        // Step 1: Open changeset
        openChangeset { result in
            switch result {
            case .success(let changesetId):
                print("Opened changeset \(changesetId)")
                localNode.changeset = changesetId  // ✅ Modify local copy
                
                // Step 2: Update node
                self.updateNode2(node: &localNode) { updateResult in
                    switch updateResult {
                    case .success(let newVersion):
                        localNode.version = newVersion  // ✅ Modify local copy
                        DispatchQueue.main.async {
                            self.dbInstance.updateNodeVersion(nodeId: String(localNode.id), version: newVersion)
                        }
                        // Step 3: Close changeset
                        self.closeChangeset(id: String(changesetId), completion: completion)

                    case .failure(let updateError):
                        completion(.failure(updateError))
                    }
                }
                
            case .failure(let openError):
                completion(.failure(openError))
            }
        }
    }



    
    func createNode(node: inout OSMNode, completion: @escaping (Result<Bool, Error>) -> Void) {
        var localNode = node  // ✅ Create a local copy to avoid `inout` capture

        openChangeset { result in
            switch result {
            case .success(let changesetId):
                localNode.changeset = changesetId  // ✅ Modify local copy
                
                self.uploadNode(node: &localNode) { uploadResult in
                    switch uploadResult {
                    case .success:
                        self.closeChangeset(id: String(changesetId)) { closeResult in
                            switch closeResult {
                            case .success:
                                completion(.success(true))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
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
    func syncWay(way: inout OSMWay, completion: @escaping (Result<Bool, Error>) -> Void) {
        var localWay = way  // ✅ Create a local copy to avoid `inout` capture

        openChangeset { result in
            switch result {
            case .success(let changesetId):
                print("Opening changeset")
                localWay.changeset = changesetId  // ✅ Modify local copy
                
                // Step 2: Update way
                self.updateWay2(way: &localWay) { updateResult in
                    switch updateResult {
                    case .success(let newVersion):
                        localWay.version = newVersion
                        DispatchQueue.main.async {
                            self.dbInstance.updateWayVersion(wayId: String(localWay.id), version: newVersion)
                        }

                        // Step 3: Close changeset
                        self.closeChangeset(id: String(changesetId)) { closeResult in
                            switch closeResult {
                            case .success:
                                print("Closing changeset")
                                completion(.success(true))
                            case .failure(let closeError):
                                completion(.failure(closeError))
                            }
                        }

                    case .failure(let updateError):
                        completion(.failure(updateError))
                    }
                }

            case .failure(let openError):
                completion(.failure(openError))
            }
        }
    }


}

// POSM has two components
// Web ROR (ruby on rails) component -> handles /create,/modify -> No workspaces implementation POSM token
// CGIMap component -> /changeset (create,upload,close) -> Workspaces + auth token integration-> TDEI token + workspace

