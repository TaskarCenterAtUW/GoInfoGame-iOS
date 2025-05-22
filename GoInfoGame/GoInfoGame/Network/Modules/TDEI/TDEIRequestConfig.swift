//
//  TDEIAPIConfiguration.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

struct TDEIRequestConfig: APIRequestConfig {
    var environment: ServerEnvironment {
        TDEIServerEnv(env: AppEnvManager.shared.current)
    }
}
