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
    
    /// Our own Panoramax instance for each environment. The URL is saved in every photo's
    /// `ext:street_images` tag, so each one must be a permanent hostname.
    /// Stage and prod use the dev instance until their own instances exist.
    /// `PANORAMAX_BASE_URL` in Secrets.xcconfig, when set, overrides this for local testing.
    var panoramaxBaseURL: String {
        switch self {
        case .development:
            return Self.panoramaxDevURL
        case .staging:
            return Self.panoramaxDevURL
        case .production:
            return Self.panoramaxDevURL
        }
    }

    // Azure's default hostname. Move to a permanent custom domain before production
    // photos are written, or saved photo URLs will break when the host changes.
    private static let panoramaxDevURL = "https://panoramax-dev-faaadghgcfgwcchk.westus2-01.azurewebsites.net"
    
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
