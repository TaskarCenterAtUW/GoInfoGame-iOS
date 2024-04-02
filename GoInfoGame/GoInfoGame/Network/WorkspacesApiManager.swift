//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation
// Singleton object that deals with workspaces APIs

class WorkspacesApiManager {
    
    static let shared = WorkspacesApiManager()
    private let listingURL = "https://www.jsonkeeper.com/b/Q80Q"
    private init() {}
    
    // fetches the workspaces based on latitiude and longitude
    func fetchWorkspaces(lat:String, lon: String, _ completion:@escaping (Result<WorkSpacesResponse, Error>)-> Void) {
        
        var request = URLRequest(url: URL(string: self.listingURL)!,timeoutInterval: Double.infinity)
       
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
          guard let data = data else {
            print(String(describing: error))
            return
          }
        let theDecoder = JSONDecoder()
        theDecoder.dateDecodingStrategy = .iso8601
            do {
                let decodedData = try theDecoder.decode(WorkSpacesResponse.self, from: data)
                completion(.success(decodedData))
            } catch  {
                completion(.failure(error))
            }
          
        }

        task.resume()


    }
    
}
