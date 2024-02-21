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
    
    private let osmConnection = OSMConnection(config: OSMConfig.testOSM, currentChangesetId: nil, userCreds: OSMLogin.testOSM)
    
    func syncData() async  {
        
        if(isSynching){
            print("Already syncing")
            return
        }
        else {
            isSynching = true
        }
        let changesets = dbInstance.getChangesets()
        print("Starting to sync data")
        var nodesToSync: [String:StoredNode] = [:]
        for changeset in changesets {
            // Get the element type
            if changeset.elementType == .node {
                print("Syncing node")
                // Get the node
                if let node  = dbInstance.getNode(id: changeset.elementId) {
                    nodesToSync[changeset.id] = node
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
            osmConnection.openChangeSet { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func closeChangeset(id:String ) async -> Result<Bool,Error> {
        
        await withCheckedContinuation { continuation in
            osmConnection.closeChangeSet(id: id) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    // utility function to act as substitute for osmConnection functions
    func updateNode(node: inout OSMNode) async -> Result<Int,Error> {
        await withCheckedContinuation { continuation in
            osmConnection.updateNode(node: &node, tags: [:]) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    
    /**
            Syncs the node along with the updated
     */
    func syncNode(node: inout OSMNode) async -> Result<Bool,Error> {
        do {
                // open changeset
                let changesetId = try await openChangeset().get()
                // update node
                node.changeset = changesetId
                // close changeset
                let newVersion = try await updateNode(node: &node).get()
                node.version = newVersion
                // Give back the new version and other stuff.
                let closeResult = try await closeChangeset(id: String(changesetId)).get()
            
            return .success(true)
            
        } catch (let error){
            print(error)
            return .failure(error)
        }
    }
}
