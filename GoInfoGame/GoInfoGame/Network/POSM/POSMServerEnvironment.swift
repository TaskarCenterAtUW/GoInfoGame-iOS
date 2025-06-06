//
//  POSMAPIEnvironment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

struct POSMServerEnv: ServerEnvironment {
    let env: AppEnv

    var baseURL: URL {
        switch env {
        case .staging: return URL(string: "https://osm-workspaces-proxy.azurewebsites.net/stage/api/0.6")!
        case .production: return URL(string: "https://osm-workspaces-proxy.azurewebsites.net/prod/api/0.6")!
        case .dev: return URL(string: "https://osm-workspaces-proxy.azurewebsites.net/dev/api/0.6")!
        }
    }
}
