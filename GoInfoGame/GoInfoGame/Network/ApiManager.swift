//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation
import osmapi

enum SetupType {
    case workspace
    case login
    case osm
    case userProfile
}

// Singleton object that deals with APIs
class ApiManager {
    
    static let shared = ApiManager()
    private init() {}
    
    func performRequest<T: Decodable>(to endpoint: APIEndpoint, setupType: SetupType, modelType: T.Type, useJSON:Bool = true, completion: @escaping (Result<T, Error>) -> Void) {
        
        var finalUrl: URL?
        switch setupType {
        case .workspace:
            finalUrl = APIConfiguration.shared.workspaceUrl(for: endpoint)
        case .login:
            finalUrl = APIConfiguration.shared.loginUrl(for: endpoint)
        case .osm:
            finalUrl = APIConfiguration.shared.osmUrl(for: endpoint)
        case .userProfile:
            finalUrl = APIConfiguration.shared.userProfileUrl(for: endpoint)
        }
        
        guard let url = finalUrl else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = endpoint.method
        
        if let httpBody = endpoint.body {
            request.httpBody = httpBody
        }
        
        if let headers = endpoint.headers {
               for (key, value) in headers {
                   request.setValue(value, forHTTPHeaderField: key)
               }
           }
        
       
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
                print(noDataError.localizedDescription)
                completion(.failure(noDataError))
                return
            }
            
            if useJSON {
                
                do {
                    let theDecoder = JSONDecoder()
                    theDecoder.dateDecodingStrategy = .iso8601
                    let decodedData = try theDecoder.decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    print("Failed to decode data: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
            else {
                do{
                    let decodedString = try String(data: data, encoding: .utf8)!
                    completion(.success(decodedString as! T))
                }
                catch {
                    print("Failed to decode the non JSON: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
