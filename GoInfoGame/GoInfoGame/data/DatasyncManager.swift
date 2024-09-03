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
    
    func syncDataToOSM( completionHandler: @escaping ()-> Void?)  {
        Task {
            await syncData()
            completionHandler()
        }
    }
    
    /// *** Terminating app due to uncaught exception 'RLMException', reason: 'Realm accessed from incorrect thread.'
    ///  To fix the above error added @mainActor
    @MainActor
    func syncData() async  {
        if(isSynching){
            print("Already syncing")
            return
        }
        else {
            isSynching = true
        }
        
        //TODO: uncomment later
        // check if the user is logged in
        // if user not logged in, isSynching-false and return
//        guard let accessToken = osmConnection.accessToken else {
//            isSynching = false
//            return
//        }
        let changesets = dbInstance.getChangesets()
        print("Starting to sync data")
        var nodesToSync: [String:StoredNode] = [:]
        var waysToSync: [String:StoredWay] = [:]
        for changeset in changesets {
            // Get the element type
            if changeset.elementType == .node {
                print("Syncing node")
                // Get the node
                if let node  = dbInstance.getNode(id: changeset.elementId) {
                    nodesToSync[changeset.id] = node
                }
            }else if changeset.elementType == .way {
                print("Syncing Way")
                // Get the way
                if let way = dbInstance.getWay(id: changeset.elementId) {
                    waysToSync[changeset.id] = way
                }
            }
        }
        
        // sync each
        for (key,node) in nodesToSync {
            var payload = node.asOSMNode()
            let result = await syncNode(node: &payload)
            switch result{
            case .success(let isFinished):
                print("Synced \(payload)")
                DispatchQueue.main.async {
                    // your code here
                    self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                }
                
            case .failure(let error):
                print("Failed to sync \(payload)")
            }
        }
        // TODO: Add logic to sync Way
        for (key,way) in waysToSync {
            var payload = way.asOSMWay()
            // update the way
            let result = await syncWay(way: &payload)
            switch result{
            case .success(let isFinished):
                print("Synced \(payload)")
                DispatchQueue.main.async {
                    // your code here
                    self.dbInstance.assignChangesetId(obj: key, changesetId: payload.changeset)
                }
                
            case .failure(let error):
                print("Failed to sync \(payload)")
            }
            
        }
        isSynching = false
        
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
    
    func openChangeset() async -> Result<Int,Error> {
        
        await withCheckedContinuation { continuation in
            
            var versionNumber = ""
            var buildNumber = ""
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                versionNumber = version
                buildNumber = build
            }
            
            let createdBy = "\(versionNumber)(\(buildNumber))"
            
            let osmPayloadString = OSMChangesetPayload(createdByTag: createdBy).toPayload()
            
            let osmPayload = osmPayloadString.data(using: .utf8)
             
            
            let workspaceId = KeychainManager.load(key: "workspaceID")
            
            if let accessToken = KeychainManager.load(key: "accessToken") {
                
                ApiManager.shared.performRequest(to: .openChangesets(accessToken, workspaceId ?? "" ,osmPayload!), setupType: .osm, modelType: Int.self) { result in
                    switch result {
                    case .success(let changesetID):
                      //  self.currentChangesetId = changesetID
                         print("changesetID is ---\(changesetID)")
                        continuation.resume(returning: .success(changesetID))
                    case .failure(let error):
                        print(error)
                        continuation.resume(returning: .failure(error))
                    }
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
    
    func closeChangeset(id:String ) async -> Result<Bool,Error> {
        
        
        
        await withCheckedContinuation { continuation in
            osmConnection.closeChangeSet(id: id) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // utility function to act as substitute for osmConnection functions
    func updateWay(way: inout OSMWay) async -> Result<Int, Error> {
        var localWay = way

        let result: Result<Int, Error> = await withCheckedContinuation { continuation in
            let wayBodyString = localWay.toPayload()
            let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">"+wayBodyString+"</osmChange>"
            let workspaceId = KeychainManager.load(key: "workspaceID")
            
            let wayBody = changesetUploadBody.data(using: .utf8)
            let wayId = "\(localWay.id)"
            // Create the changeset upload payload
            let newVersion = way.version + 1

            if let accessToken = KeychainManager.load(key: "accessToken") {
                ApiManager.shared.performRequest(to: .uploadChangeset(accessToken,"\(way.changeset)",workspaceId ?? "",wayBody! ), setupType: .osm, modelType: String.self,useJSON: false) { result in
                    switch result {
                    case .success(let success):
                        localWay.tags.forEach { (key: String, value: String) in
                            localWay.tags[key] = value
                        }
                        continuation.resume(returning: .success(newVersion))
                    case .failure(let error):
                        // handle 409
//                        let latestWay = await self.fetchWay2(wayId: wayId).get()
//                        let mergedWay = self.mergeWays(localWay: way, latestWay: latestWay)
                        
                        print(error)
                        continuation.resume(returning: .failure(error))
                    }
                }
            } else {
                continuation.resume(returning: .failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            }
        }
        way = localWay
        return result
    }
    
    // utility function to act as substitute for osmConnection functions
    func updateNode(node: inout OSMNode) async -> Result<Int, Error> {
        var localNode = node

        let result: Result<Int, Error> = await withCheckedContinuation { continuation in
            let nodeBodyString = localNode.toPayload()
            let changesetUploadBody = "<osmChange version=\"0.6\" generator=\"GIG Change generator\">"+nodeBodyString+"</osmChange>"
            let workspaceId = KeychainManager.load(key: "workspaceID")
            
            let nodeBody = changesetUploadBody.data(using: .utf8)
            let nodeId = "\(localNode.id)"
            // Create the changeset upload payload
            let newVersion = node.version + 1

            if let accessToken = KeychainManager.load(key: "accessToken") {
                ApiManager.shared.performRequest(to: .uploadChangeset(accessToken,"\(node.changeset)",workspaceId ?? "",nodeBody! ), setupType: .osm, modelType: String.self,useJSON: false) { result in
                    switch result {
                    case .success(let success):
                        localNode.tags.forEach { (key: String, value: String) in
                            localNode.tags[key] = value
                        }
                        continuation.resume(returning: .success(newVersion))
                    case .failure(let error):
                        print(error)
                        continuation.resume(returning: .failure(error))
                    }
                }
            } else {
                continuation.resume(returning: .failure(NSError(domain: "No AccessToken", code: 0, userInfo: nil)))
            }
        }
        node = localNode
        return result
    }
    
    func updateWay2(way:inout OSMWay) async -> Result<Int,Error>{
        let updatedResult = await self.updateWay(way: &way)
        let wayId = "\(way.id)"
        do {
            switch updatedResult {
            case .success(let value):
                return updatedResult
            case .failure(let error):
                // Check 409 here.
                if (error as NSError).code == 409 {
                    let updatedWay = try await self.fetchWay2(wayId: wayId).get()
                    var mergedWay = self.mergeWays(localWay: way, latestWay: updatedWay)
                    print("Local way")
                    print(way)
                    print("Merged way ")
                    print(mergedWay)
                    let mergeResult = await self.updateWay(way: &mergedWay)
                    return mergeResult

                } else {
                    return updatedResult
                }
            }
        }
        catch (let e){
            return .failure(e)
        }
    }
    
    func updateNode2(node: inout OSMNode) async -> Result<Int,Error> {
        let updatedResult = await self.updateNode(node: &node)
        let nodeId = "\(node.id)"
        do {
            switch updatedResult {
            case .success(let value):
                return updatedResult
            case .failure(let error):
                if (error as NSError).code == 409 {
                    let updatedNode = try await self.fetchNode2(nodeId: nodeId).get()
                    var mergedNode = self.mergeNodes(localNode: node, latestNode: updatedNode)
                    print("Local Node")
                    print(node)
                    print("Merged Node ")
                    print(mergedNode)
                    let mergeResult = await self.updateNode(node: &mergedNode)
                    return mergeResult
                } else {
                    return updatedResult
                }
            }
        } catch(let e) {
            return .failure(e)
            
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

    
    func fetchWay2(wayId:String) async -> Result<OSMWay,Error>{
        
        let result: Result<OSMWay,Error> = await withCheckedContinuation { continuation in
            let workspaceID = KeychainManager.load(key: "workspaceID")
            ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID!, wayId), setupType: .osm, modelType: OSMWayResponse.self) { result in
                switch result {
                case .success(let osmwayResponse):
                    let osmway = osmwayResponse.elements.first
                    continuation.resume(returning: .success(osmway!))

                case .failure(let error):
                     continuation.resume(returning: .failure(error))
                }
            }
        }
        return result
        
    }
    
    func fetchNode2(nodeId:String) async -> Result<OSMNode,Error>{
        
        let result: Result<OSMNode,Error> = await withCheckedContinuation { continuation in
            let workspaceID = KeychainManager.load(key: "workspaceID")
            ApiManager.shared.performRequest(to: .fetchLatestWay(workspaceID!, nodeId), setupType: .osm, modelType: OSMNodeResponse.self) { result in
                switch result {
                case .success(let osNodeResponse):
                    let osmnode = osNodeResponse.elements.first
                    continuation.resume(returning: .success(osmnode!))

                case .failure(let error):
                     continuation.resume(returning: .failure(error))
                }
            }
        }
        return result
        
    }
   
    /**
            Syncs the node along with the updated
     */
    @MainActor
    func syncNode(node: inout OSMNode) async -> Result<Bool,Error> {
        do {
                // open changeset
                let changesetId = try await openChangeset().get()
                // update node
                node.changeset = changesetId
                // close changeset
                let newVersion = try await updateNode(node: &node).get()
                node.version = newVersion
                self.dbInstance.updateNodeVersion(nodeId: String(node.id), version: newVersion)
                // Give back the new version and other stuff.
                let closeResult = try await closeChangeset(id: String(changesetId)).get()
            
            return .success(true)
            
        } catch (let error){
            print(error)
            return .failure(error)
        }
    }
    
    @MainActor
    func syncWay(way: inout OSMWay)  async -> Result<Bool,Error> {
        do {
                // open changeset
                let changesetId = try await openChangeset().get()
                // update node
                print("Opening changeset")
                way.changeset = changesetId
                // close changeset
                let newVersion = try await updateWay2(way: &way).get()
                // update the version in databse
                self.dbInstance.updateWayVersion(wayId: String(way.id), version: newVersion)
                way.version = newVersion
                // Give back the new version and other stuff.
                print("Closing changeset")
                let closeResult = try await closeChangeset(id: String(changesetId)).get()
            
            return .success(true)
            
        } catch (let error){
            print(error)
            return .failure(error)
        }
    }
}
