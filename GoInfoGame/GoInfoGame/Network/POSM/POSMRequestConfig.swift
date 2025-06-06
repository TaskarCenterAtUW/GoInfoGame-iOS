//
//  POSMAPIConfiguration.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

struct POSMRequestConfig: APIRequestConfig {
    var environment: ServerEnvironment {
        POSMServerEnv(env: AppEnvManager.shared.current)
    }
}

