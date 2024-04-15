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
    let apiClient = APIClient(baseURL: URL(string: "https://tdei-api-dev.azurewebsites.net/api/v1")!)
    private init() {}
    
    struct LoginRequest: Encodable {
      let username: String
      let password: String
    }
    
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
    // Function to call the login API
    func login(username: String, password: String, completion: @escaping (Result<TDEILoginResponse, Error>) -> Void) {
      let loginBody = LoginRequest(username: username, password: password)
        apiClient.request(path: "/authenticate",method: "POST", body: loginBody, completion: completion)
    }
}
