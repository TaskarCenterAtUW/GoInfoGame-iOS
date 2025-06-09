//
//  WorkspacesApiManager.swift
//  GoInfoGame
//
//  Created by Naresh Devalapally on 4/1/24.
//

import Foundation
import osmapi
import SwiftUI

enum SetupType {
    case workspace
    case login
    case osm
    case userProfile
    case kartaview
}

// Singleton object that deals with APIs
class ApiManager {
    
    static let shared = ApiManager()
    private init() {}
    
    func performRequest<T: Decodable>(to endpoint: APIEndpoint, setupType: SetupType, modelType: T.Type, useJSON:Bool = true, completion: @escaping (Result<T, APIError>) -> Void) {
        
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
        case .kartaview:
            finalUrl = APIConfiguration.shared.kartaViewUrl(for: endpoint)
        }
        
        guard let url = finalUrl else {
            print("Invalid URL")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.httpMethod = endpoint.method
        
        if let formData = endpoint.formData {
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            
            // Iterate over the form data and append to body
            for param in formData {
                guard let paramName = param["key"] as? String else {
                    print("Invalid parameter key")
                    continue
                }
                
                // Append the boundary
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                
                if let stringValue = param["value"] as? String {
                    // Handle text data
                    body.append("Content-Disposition: form-data; name=\"\(paramName)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(stringValue)\r\n".data(using: .utf8)!)
                } else if let paramSrc = param["src"] as? Data {
                    // Handle file upload
                    do {
                        let filename = param["filename"] as? String ?? "image.jpeg"
                        let contentType = param["contentType"] as? String ?? "application/octet-stream" // Default content type
                        
                        // Append headers for file data
                        body.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
                        body.append(paramSrc)
                        body.append("\r\n".data(using: .utf8)!)
                    } catch {
                        print("Error reading file data: \(error.localizedDescription)")
                    }
                } else {
                    print("Unsupported value type for formData key: \(paramName)")
                }
            }
            
            // End the form with the final boundary
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            // Set the HTTP body
            request.httpBody = body
        } else if let httpBody = endpoint.body {
            request.httpBody = httpBody
        }
        
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else {
                completion(.failure(APIError.custom("No data returned")))
                return
            }
            if let error = error {
                print("Request failed with error: \(error.localizedDescription)")
                completion(.failure(APIError.custom("Request failed with error: \(error.localizedDescription)")))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401,
               request.url!.lastPathComponent.contains("refresh-token") == false,
               request.url!.lastPathComponent.contains("authenticate") == false {
                print("Failed requests: \(String(describing: request.url))")
                TokenRefresher.shared.refreshToken { [weak self] status in
                    if status {
                        let accessToken = KeychainManager.load(key: "accessToken") ?? ""
                        var headers = endpoint.headers
                        headers?["Authorization"] = "Bearer \(accessToken)"
                        let urlEndPont = APIEndpoint(path: endpoint.path, method: endpoint.method, body: endpoint.body, headers: headers, formData: endpoint.formData)
                        self?.performRequest(to: urlEndPont, setupType: setupType, modelType: modelType, completion: completion)
                    }
                    else {
                        completion(.failure(APIError.custom("Token refresh failed")))
                        DispatchQueue.main.async {
                            if let window = UIApplication.window() {
                                Utilities.clearAllData()
                                window.rootViewController = UIHostingController(rootView: PosmLoginView())
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    NotificationCenter.default.post(name: Notification.Name("SessionExpired"), object: nil)
                                }
                            }
                        }
                    }
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.custom("No data returned")))
                return
            }
            
            if useJSON {
                do {
                    if data.isEmpty {
                        if T.self == Bool.self {
                            completion(.success(true as! T)) // Assuming success means `true` and this is for cloae changeset
                            return
                        } else {
                            completion(.failure(APIError.custom("Unexpected empty response")))
                            return
                        }
                    }
                    
                    
                    let theDecoder = JSONDecoder()
                    theDecoder.dateDecodingStrategy = .iso8601
                    let decodedData = try theDecoder.decode(T.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    print("Failed to decode data: \(error.localizedDescription)")
                    if let dataString = String(data: data, encoding: .utf8), !dataString.isEmpty {
                        completion(.failure(APIError.custom("Not a valid JSON \(dataString)")))
                    } else {
                        completion(.failure(APIError.custom("Empty JSON")))
                    }
                    
                    return
                }
            }
            else {
                if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 409:
                        let conflictError = NSError(domain: "goinfogame", code: 409, userInfo: [NSLocalizedDescriptionKey: "version mismatch"])
                        completion(.failure(APIError.conflict))
                        
                    case 200:
                        do {
                            if let decodedString = String(data: data, encoding: .utf8) {
                                completion(.success(decodedString as! T))
                            } else {
                                completion(.failure(APIError.custom("Failed to decode string")))
                            }
                        } catch {
                            print("Failed to decode the non JSON: \(error.localizedDescription)")
                            completion(.failure(APIError.custom("Failed to decode non JSON")))
                        }
                        
                    default:
                        completion(.failure(APIError(statusCode: response.statusCode)))
                    }
                } else {
                    completion(.failure(APIError.custom("No valid HTTP response received")))
                }
            }
        }
        task.resume()
    }
}
