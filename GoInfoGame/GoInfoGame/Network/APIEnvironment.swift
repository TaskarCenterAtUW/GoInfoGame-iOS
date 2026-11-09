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
    
    /// Our own Panoramax instance for this environment, from `PANORAMAX_BASE_URL_DEV`,
    /// `_STAGE` or `_PROD` in Secrets.xcconfig. The URL is saved in every photo's
    /// `ext:street_images` tag, so each one must be a permanent hostname.
    /// Falls back to the dev instance when the environment's key is not set.
    var panoramaxBaseURL: String { panoramaxBaseURL(info: Bundle.main.infoDictionary) }

    /// The upload token for this environment's instance, from `PANORAMAX_TOKEN_DEV`,
    /// `_STAGE` or `_PROD` in Secrets.xcconfig. Empty when it is not set.
    var panoramaxToken: String { panoramaxToken(info: Bundle.main.infoDictionary) }

    func panoramaxBaseURL(info: [String: Any]?) -> String {
        guard let url = Self.configValue("PANORAMAX_BASE_URL_\(configSuffix)", in: info) else {
            return Self.panoramaxDevURL
        }
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }

    func panoramaxToken(info: [String: Any]?) -> String {
        Self.configValue("PANORAMAX_TOKEN_\(configSuffix)", in: info) ?? ""
    }

    /// Suffix of this environment's keys in Secrets.xcconfig: DEV, STAGE or PROD.
    private var configSuffix: String { rawValue.uppercased() }

    /// A build setting passed through Info.plist, or nil when it is empty or was never
    /// defined (Xcode then leaves the `$(KEY)` placeholder or an empty string).
    private static func configValue(_ key: String, in info: [String: Any]?) -> String? {
        guard let value = (info?[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty, !value.hasPrefix("$(") else { return nil }
        return value
    }

    // Used when Secrets.xcconfig has no URL for the environment (e.g. CI). Azure's default
    // hostname: move to a permanent custom domain before production photos are written.
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
