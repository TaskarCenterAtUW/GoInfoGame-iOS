//
//  WorkspaceAdapter.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 23/05/25.
//

protocol APIRequestAdapter {
    var headers: [String: String] { get }
}


struct WorkspaceAdapter: APIRequestAdapter {
    var headers: [String : String] {
        var headers: [String: String] = [:]
        if let workspaceId = AuthSessionManager.shared.worksapaceId {
            headers["X-Workspace"] = workspaceId
        }
        return headers
    }
}

struct AuthAdapter: APIRequestAdapter {
    var headers: [String : String] {
        var headers: [String: String] = [:]
        if let token = AuthSessionManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
}

