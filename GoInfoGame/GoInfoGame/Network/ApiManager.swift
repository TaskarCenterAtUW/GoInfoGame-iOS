//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation
// Singleton object that deals with workspaces APIs

class ApiManager {
    
    static let shared = ApiManager()
    private let listingURL = "https://api.workspaces-stage.sidewalks.washington.edu/api/v1/workspaces/mine"
    private init() {}
    
    // fetches the workspaces based on latitiude and longitude
    func fetchWorkspaces(lat: String, lon: String, completion: @escaping (Result<[Workspace], Error>) -> Void) {
        var request = URLRequest(url: URL(string: self.listingURL)!, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "Data is nil", code: -1, userInfo: nil)))
                }
                return
            }

            let theDecoder = JSONDecoder()
            theDecoder.dateDecodingStrategy = .iso8601
            do {
                let workspaces = try theDecoder.decode([Workspace].self, from: data)
                completion(.success(workspaces))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // fetches the long quests based on workspace id
    func fetchLongQuests(workspaceId: String, completion: @escaping (Result<[LongFormModel], Error>) -> Void) {
        
        let longQuestUrl = "https://api.workspaces-stage.sidewalks.washington.edu/api/v1/workspaces/\(workspaceId)/quests/long"
        var request = URLRequest(url: URL(string: longQuestUrl)!, timeoutInterval: Double.infinity)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "Data is nil", code: -1, userInfo: nil)))
                }
                return
            }

            let theDecoder = JSONDecoder()
            theDecoder.dateDecodingStrategy = .iso8601
            do {
                let longQuests = try theDecoder.decode([LongFormModel].self, from: data)
                self.saveLongQuestsToDefaults(longQuestJson: longQuests)
                completion(.success(longQuests))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func login(username: String, password: String, completion: @escaping (LoginResponse)-> Void){
        
        let postingJSON = [
            "username": username,
            "password": password
        ]
        
        let postingBody  = try? JSONSerialization.data(withJSONObject: postingJSON)
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        let loginUrl = "https://tdei-gateway-stage.azurewebsites.net/api/v1/authenticate"
        let request: NSMutableURLRequest = NSMutableURLRequest()
        request.url = NSURL(string: loginUrl) as URL?
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        //add params to request
        request.httpBody = postingBody
        let dataTask = session.dataTask(with: request as URLRequest) { (data: Data?, response:URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                return
            }
            if((error) != nil) {
                print(error!.localizedDescription)
            } else {
                print("Succes:")
                do {
                    
                    
                    
                    if let success = try? JSONDecoder().decode(PosmLoginSuccessResponse.self, from: data) {
                        completion(.success(success))
                    }
                    else if let failure = try? JSONDecoder().decode(PosmLoginErrorResponse.self, from: data) {
                        completion(.failure(failure))
                    } else {
                        completion(.error(error?.localizedDescription ?? "An error occured"))
                    }
                } catch let error as NSError {
                    print(error)
                    completion(.error(error.localizedDescription))
                }
            }
        }
        dataTask.resume()
        
    }
    
    func saveLongQuestsToDefaults(longQuestJson: [LongFormModel]) {
        do {
           try FileStorageManager.shared.save(questModels: longQuestJson, to: "longQuestJson")
        } catch {
            print("Failed to save file: \(error)")
        }
    }
}
