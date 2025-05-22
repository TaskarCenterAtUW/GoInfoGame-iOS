//
//  TDEIServerEnvironment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

struct TDEIServerEnv: ServerEnvironment {
    let env: AppEnv

    var baseURL: URL {
        switch env {
        case .staging: return URL(string: "https://tdei-gateway-stage.azurewebsites.net/api/v1")!
        case .production: return URL(string: "https://tdei-gateway-prod.azurewebsites.net/api/v1")!
        case .dev: return URL(string: "https://tdei-api-dev.azurewebsites.net/api/v1")!
        }
    }
}
