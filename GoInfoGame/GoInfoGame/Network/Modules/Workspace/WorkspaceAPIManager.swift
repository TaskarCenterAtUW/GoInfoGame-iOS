//
//  WorkspaceAPIManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

final class WorkspaceAPIManager: WorkspaceAPIProtocol {
    
    static let shared = WorkspaceAPIManager()
    private let config = WorkspaceRequestConfig()
    private let authAdapter = AuthAdapter()
        
    private init() {}
    
    func fetchWorkspaces(completion: @escaping (Result<[Workspace], APIError>) -> Void) {

        let request = APIRequest(
            path: "/workspaces/mine",
            method: "GET",
            headers: ["Content-Type": "application/json"]
        )
                
        APIRequestPerformer.perform(request: request, config: config, adapters: [authAdapter], completion: completion)
    }
    
    func fetchLongQuestsFor(workspaceId: String, completion: @escaping (Result<LongFormResponse, APIError>) -> Void) {
        
        let request = APIRequest(
            path: "/workspaces/\(workspaceId)/quests/long",
            method: "GET",
            headers: ["Content-Type": "application/json"]
        )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }
}
