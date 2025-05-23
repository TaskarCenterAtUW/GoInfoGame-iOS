//
//  KartaviewAPIEnvironment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

struct KartaviewServerEnv: ServerEnvironment {
    let env: AppEnv

    var baseURL: URL {
        switch env {
        case .staging: return URL(string: "https://api.openstreetcam.org/1.0")!
        case .production: return URL(string: "https://api.openstreetcam.org/1.0")!
        case .dev: return URL(string: "https://api.openstreetcam.org/1.0")!
        }
    }
}
