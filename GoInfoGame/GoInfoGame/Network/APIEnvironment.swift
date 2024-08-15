//
//  Environment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

enum Environment {
    case development
    case staging
    case production
    case osm
    
    var workspaceBaseURL: String {
        switch self {
        case .development:
            return "https://api.workspaces-dev.sidewalks.washington.edu/api/v1"
        case .staging:
            return "https://api.workspaces-stage.sidewalks.washington.edu/api/v1"
        case .production:
            return "https://api.workspaces-prod.sidewalks.washington.edu/api/v1"
        case .osm:
            return ""
        }
    }
    
    var workspaceLoginURL: String {
        switch self {
        case .development:
            return "https://tdei-gateway-dev.azurewebsites.net/api/v1"
        case .staging:
            return "https://tdei-gateway-stage.azurewebsites.net/api/v1"
        case .production:
            return "https://tdei-gateway-prod.azurewebsites.net/api/v1"
        case .osm:
            return ""
        }
    }
    
    var workspaceOSMURL: String {
        switch self {
        case .development:
            return "https://osm.workspaces-dev.sidewalks.washington.edu/api/0.6/"
        case .staging:
            return "https://osm.workspaces-stage.sidewalks.washington.edu/api/0.6/"
        case .production:
            return "https://osm.workspaces-prod.sidewalks.washington.edu/api/0.6/"
        case .osm:
            return ""
        }
    }
}
