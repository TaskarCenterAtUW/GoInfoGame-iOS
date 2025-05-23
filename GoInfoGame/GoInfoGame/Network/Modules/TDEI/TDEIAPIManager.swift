//
//  TDEIAPIManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

final class TDEIAPIManager {
    static let shared = TDEIAPIManager()
    private let config = TDEIRequestConfig()
        
    private init() {}
    
    func login(username: String, password: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void) {
        let body = [
               "username": username,
               "password": password
           ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
               completion(.failure(.custom("Invalid JSON format")))
               return
           }
        
        let request = APIRequest(
                path: "/authenticate",
                method: "POST",
                headers: ["Content-Type": "application/json"], body: jsonData  
            )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }
    
    func refreshToken(refreshToken: String, completion: @escaping (Result<PosmLoginSuccessResponse, APIError>) -> Void) {
        
        let postBody  = refreshToken.data(using: .utf8)
        
        let request = APIRequest(
            path: "/refresh-token",
            method: "POST",
            headers: ["Content-Type": "application/json"], body: postBody
        )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }
    

    func fetchUserProfile(completion: @escaping (Result<TdeiUserProfile, APIError>) -> Void) {
        guard let accessToken = AuthSessionManager.shared.accessToken, let userName = AuthSessionManager.shared.username else {
            completion(.failure(.unauthorized))
            return
        }
        
        let request = APIRequest(
            path: "/user-profile?user_name=\(userName)",
            method: "GET",
            headers: ["Content-Type": "application/json", "Authorization" : "Bearer \(accessToken)"]
        )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
        
    }
        

}
