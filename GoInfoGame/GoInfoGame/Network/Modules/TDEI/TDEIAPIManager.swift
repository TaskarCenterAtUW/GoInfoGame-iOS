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
        
        let loginConfig = TDEIRequestConfig()
    
        APIRequestPerformer.perform(request: request, config: loginConfig, completion: completion)
    }

}
