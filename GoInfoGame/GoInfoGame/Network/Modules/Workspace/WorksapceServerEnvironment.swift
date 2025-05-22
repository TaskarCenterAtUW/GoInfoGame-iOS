//
//  WorksapceServerEnvironment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

struct WorkspaceServerEnv: ServerEnvironment {
    let env: AppEnv

    var baseURL: URL {
        switch env {
        case .staging: return URL(string: "https://api.workspaces-stage.sidewalks.washington.edu/api/v1")!
        case .production: return URL(string: "https://api.workspaces.sidewalks.washington.edu/api/v1")!
        case .dev: return URL(string: "https://api.workspaces-dev.sidewalks.washington.edu/api/v1")!
        }
    }
}

