//
//  KartaviewAPIConfiguration.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

struct KartaviewRequestConfig: APIRequestConfig {
    var environment: ServerEnvironment {
        KartaviewServerEnv(env: AppEnvManager.shared.current)
    }
}

