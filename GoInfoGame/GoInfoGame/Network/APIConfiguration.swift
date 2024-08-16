//
//  APIConfiguration.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 16/08/24.
//

import Foundation

class APIConfiguration {
    static let shared = APIConfiguration()
    
    var environment: APIEnvironment = .staging
    
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
}
