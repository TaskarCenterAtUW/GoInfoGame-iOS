//
//  APIConfiguration.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

class APIConfiguration {
    static let shared = APIConfiguration()
    
    static let environmentKey = "APIEnvironment"
        
        var environment: APIEnvironment {
            get {
                if let savedValue = UserDefaults.standard.string(forKey: APIConfiguration.environmentKey),
                   let savedEnvironment = APIEnvironment(rawValue: savedValue) {
                    return savedEnvironment
                }
                return .production // default value
            }
            set {
                UserDefaults.standard.set(newValue.rawValue, forKey: APIConfiguration.environmentKey)
            }
        }
    
    func workspaceUrl(for endpoint: APIEndpoint) -> URL? {
        return URL(string: environment.workspaceBaseURL + endpoint.path)
    }
    
    func loginUrl(for endpoint: APIEndpoint) -> URL? {
        return URL(string: environment.loginBaseURL + endpoint.path)
    }
    
    func osmUrl(for endpoint: APIEndpoint) -> URL? {
        return URL(string:  environment.osmBaseURL + endpoint.path)
    }
    
    func userProfileUrl(for endpoint: APIEndpoint) -> URL? {
        return URL(string:  environment.userProfileBaseURL + endpoint.path)
    }
    
    func kartaViewUrl(for endpoint: APIEndpoint) -> URL? {
        return URL(string: environment.kartaViewBaseURL + endpoint.path)
    }

    func kartaViewV2Url(for endpoint: APIEndpoint) -> URL? {
        return URL(string: environment.kartaViewV2BaseURL + endpoint.path)
    }
}
