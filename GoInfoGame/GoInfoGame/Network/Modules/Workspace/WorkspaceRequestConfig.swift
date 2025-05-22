//
//  WorkspaceRequestConfig.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

struct WorkspaceRequestConfig: APIRequestConfig {
    var environment: ServerEnvironment {
        WorkspaceServerEnv(env: AppEnvManager.shared.current)
    }
}
