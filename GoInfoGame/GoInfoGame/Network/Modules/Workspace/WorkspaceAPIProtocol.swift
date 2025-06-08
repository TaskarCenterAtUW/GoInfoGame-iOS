//
//  WorkspaceAPIProtocol.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 24/05/25.
//


protocol WorkspaceAPIProtocol {
    func fetchWorkspaces(completion: @escaping (Result<[Workspace], APIError>) -> Void)
    func fetchLongQuestsFor(workspaceId: String, completion: @escaping (Result<LongFormResponse, APIError>) -> Void)
}
