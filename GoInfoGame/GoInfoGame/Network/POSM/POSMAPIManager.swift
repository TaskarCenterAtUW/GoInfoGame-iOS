//
//  POSMAPIManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import osmapi

final class POSMAPIManager: POSMAPIProtocol {
    static let shared = POSMAPIManager()
    private let config = POSMRequestConfig()
    private let workspaceAdapter = WorkspaceAdapter()
    private let authAdapter = AuthAdapter()
    

    private init() {
        
    }
    
    func fetchOSMElements(left: Double, bottom: Double, right: Double, top: Double, completion: @escaping (Result<OSMMapDataResponse, APIError>) -> Void) {
        
        let request = APIRequest(
            path: "/map.json?bbox=\(left),\(bottom),\(right),\(top)",
            method: "GET"
            )
        APIRequestPerformer.perform(request: request, config: config, adapters: [workspaceAdapter] ,completion: completion)
    }
    
    func openChangeset(osmPayload: Data?, workspaceId: String, completion: @escaping (Result<Int, APIError>) -> Void) {
        let request = APIRequest(
            path: "/changeset/create",
            method: "PUT",
            headers: [
                "Content-Type" : "application/xml"
            ], body: osmPayload
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [authAdapter, workspaceAdapter], completion: completion)
    }
    
    func uploadChangeset(changesetBody: Data?, changesetId: String, completion: @escaping (Result<String, APIError>) -> Void) {

        let request = APIRequest(
            path: "/changeset/\(changesetId)/upload",
            method: "POST",
            headers: [
                "Content-Type" : "application/xml"
            ], body: changesetBody
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [authAdapter, workspaceAdapter], completion: completion)
    }
    
    func closeChangeset(changesetId: String, completion: @escaping (Result<Bool, APIError>) -> Void) {
        let request = APIRequest(
            path: "/changeset/\(changesetId)/close",
            method: "PUT"
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [authAdapter, workspaceAdapter], completion: completion)
    }
    
    func fetchWay(wayId: String, completion: @escaping (Result<OSMWayResponse, APIError>) -> Void) {
        let request = APIRequest(
            path:  "/way/\(wayId).json",
            method: "GET"
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [workspaceAdapter], completion: completion)
    }
    
    func fetchNode(nodeId: String, completion: @escaping (Result<OSMNodeResponse, APIError>) -> Void) {
        let request = APIRequest(
            path: "/node/\(nodeId).json",
            method: "GET"
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [workspaceAdapter], completion: completion)
    }
    
    func submitNote(note: String, lat: Double, long: Double, completion: @escaping (Result<Bool, APIError>) -> Void) {
        
        let request = APIRequest(
            path: "/notes?lat=\(lat)&lon=\(long)&text=\(note)",
            method: "POST",
            headers: [
                "Content-Type": "application/xml"
            ]
        )
        APIRequestPerformer.perform(request: request, config: config, adapters: [workspaceAdapter, authAdapter], completion: completion)
    }
}


