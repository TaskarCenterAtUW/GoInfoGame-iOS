//
//  Environment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

enum APIEnvironment: String, CaseIterable {
    case development = "Development"
    case staging = "Staging"
//    case production = "Production"
//    case osm = "OSM"
//
    var workspaceBaseURL: String {
        switch self {
        case .development:
            return "https://api.workspaces-dev.sidewalks.washington.edu/api/v1"
        case .staging:
            return "https://api.workspaces-stage.sidewalks.washington.edu/api/v1"
//        case .production:
//            return "https://api.workspaces-prod.sidewalks.washington.edu/api/v1"
//        case .osm:
//            return ""
        }
    }
    
    var loginBaseURL: String {
        switch self {
        case .development:
            return "https://tdei-gateway-dev.azurewebsites.net/api/v1"
        case .staging:
            return "https://tdei-gateway-stage.azurewebsites.net/api/v1"
//        case .production:
//            return "https://tdei-gateway-prod.azurewebsites.net/api/v1"
//        case .osm:
//            return ""
        }
    }
    
    var osmBaseURL: String {
        switch self {
        case .development:
            return "https://osm.workspaces-dev.sidewalks.washington.edu/api/0.6"
        case .staging:
            return "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6"
//        case .production:
//            return "https://osm.workspaces-prod.sidewalks.washington.edu/api/0.6"
//        case .osm:
//            return ""
        }
    }
    
    var userProfileBaseURL: String {
        switch self {
        case .development:
            return "https://tdei-usermanagement-be-dev.azurewebsites.net/api/v1"
        case .staging:
            return "https://tdei-usermanagement-stage.azurewebsites.net/api/v1"
//        case .production:
//            return ""
//        case .osm:
//            return ""
        }
    }
}
