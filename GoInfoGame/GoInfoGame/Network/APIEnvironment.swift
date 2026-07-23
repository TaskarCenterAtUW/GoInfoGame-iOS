//
//  Environment.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

enum APIEnvironment: String, CaseIterable {
    case development = "dev"
    case staging = "stage"
    case production = "prod"

    var workspaceBaseURL: String {
        switch self {
        case .development:
            return "https://api.workspaces-dev.sidewalks.washington.edu/api/v1"
        case .staging:
            return "https://api.workspaces-stage.sidewalks.washington.edu/api/v1"
        case .production:
            return "https://api.workspaces.sidewalks.washington.edu/api/v1"
        }
    }
    
    var loginBaseURL: String {
        switch self {
        case .development:
            return "https://portal-api-dev.tdei.us/api/v1"
        case .staging:
            return "https://portal-api-stage.tdei.us/api/v1"
        case .production:
            return "https://portal-api.tdei.us/api/v1"
        }
    }
    
    var osmBaseURL: String {
           switch self {
           case .development:
               return "https://osm-workspaces-proxy.azurewebsites.net/dev/api/0.6"
           case .staging:
               return "https://osm-workspaces-proxy.azurewebsites.net/stage/api/0.6"
           case .production:
               return "https://osm-workspaces-proxy.azurewebsites.net/prod/api/0.6"
           }
       }
    
    var userProfileBaseURL: String {
        switch self {
        case .development:
            return "https://tdei-usermanagement-be-dev.azurewebsites.net/api/v1"
        case .staging:
            return "https://tdei-usermanagement-stage.azurewebsites.net/api/v1"
        case .production:
            return "https://tdei-usermanagement-prod.azurewebsites.net/api/v1"
        }
    }
    
    var kartaViewBaseURL: String {
        switch self {
        case .development:
            return "https://api.openstreetcam.org/1.0"
        case .staging:
            return "https://api.openstreetcam.org/1.0"
        case .production:
            return "https://api.openstreetcam.org/1.0"
        }
    }

    var kartaViewV2BaseURL: String {
        switch self {
        case .development, .staging, .production:
            return "https://api.openstreetcam.org/2.0"
        }
    }
    
    func displayString() -> String {
        switch self {
        case .development:
            return "Development"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}
