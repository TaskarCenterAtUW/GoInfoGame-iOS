//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation

enum SetupType {
    case workspace
    case login
    case osm
}

// Singleton object that deals with APIs
class ApiManager {
    
    static let shared = ApiManager()
    private init() {}
    
    func performRequest<T: Decodable>(to endpoint: APIEndpoint, setupType: SetupType, modelType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        var finalUrl: URL?
        switch setupType {
        case .workspace:
            finalUrl = APIConfiguration.shared.workspaceUrl(for: endpoint)
        case .login:
            finalUrl = APIConfiguration.shared.loginUrl(for: endpoint)
        case .osm:
            finalUrl = APIConfiguration.shared.osmUrl(for: endpoint)
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
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                print("Failed to decode data: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    
    
    
    
    
    
    
    
    
    
    /////////////////
    
//    // fetches the workspaces based on latitiude and longitude
//    func fetchWorkspaces( completion: @escaping (Result<[Workspace], Error>) -> Void) {
//        var request = URLRequest(url: URL(string: "")!, timeoutInterval: Double.infinity)
//        request.httpMethod = "GET"
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.failure(NSError(domain: "Data is nil", code: -1, userInfo: nil)))
//                }
//                return
//            }
//
//            let theDecoder = JSONDecoder()
//            theDecoder.dateDecodingStrategy = .iso8601
//            do {
//                let workspaces = try theDecoder.decode([Workspace].self, from: data)
//                completion(.success(workspaces))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//        task.resume()
//    }
//    
//    // fetches the long quests based on workspace id
//    func fetchLongQuests(workspaceId: String, completion: @escaping (Result<[LongFormModel], Error>) -> Void) {
//        
//        let longQuestUrl = "https://api.workspaces-stage.sidewalks.washington.edu/api/v1/workspaces/\(workspaceId)/quests/long"
//        var request = URLRequest(url: URL(string: longQuestUrl)!, timeoutInterval: Double.infinity)
//        request.httpMethod = "GET"
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data else {
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.failure(NSError(domain: "Data is nil", code: -1, userInfo: nil)))
//                }
//                return
//            }
//
//            let theDecoder = JSONDecoder()
//            theDecoder.dateDecodingStrategy = .iso8601
//            do {
//                let longQuests = try theDecoder.decode([LongFormModel].self, from: data)
//              //  self.saveLongQuestsToDefaults(longQuestJson: longQuests)
//                completion(.success(longQuests))
//            } catch {
//                completion(.failure(error))
//            }
//        }
//        task.resume()
//    }
    
//    func login(username: String, password: String, completion: @escaping (LoginResponse)-> Void){
//        
//        let postingJSON = [
//            "username": username,
//            "password": password
//        ]
//        
//        let postingBody  = try? JSONSerialization.data(withJSONObject: postingJSON)
//        
//        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
//        let loginUrl = "https://tdei-gateway-stage.azurewebsites.net/api/v1/authenticate"
//        let request: NSMutableURLRequest = NSMutableURLRequest()
//        request.url = NSURL(string: loginUrl) as URL?
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        //add params to request
//        request.httpBody = postingBody
//        let dataTask = session.dataTask(with: request as URLRequest) { (data: Data?, response:URLResponse?, error: Error?) -> Void in
//            guard let data = data else {
//                return
//            }
//            if((error) != nil) {
//                print(error!.localizedDescription)
//            } else {
//                print("Succes:")
//                do {
//                    
//                    
//                    
//                    if let success = try? JSONDecoder().decode(PosmLoginSuccessResponse.self, from: data) {
//                        completion(.success(success))
//                    }
//                    else if let failure = try? JSONDecoder().decode(PosmLoginErrorResponse.self, from: data) {
//                        completion(.failure(failure))
//                    } else {
//                        completion(.error(error?.localizedDescription ?? "An error occured"))
//                    }
//                } catch let error as NSError {
//                    print(error)
//                    completion(.error(error.localizedDescription))
//                }
//            }
//        }
//        dataTask.resume()
//        
//    }
}
