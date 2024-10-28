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
    case kartaview
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
        case .kartaview:
            finalUrl = APIConfiguration.shared.kartaViewUrl(for: endpoint)
        }
        
        guard let url = finalUrl else {
            print("Invalid URL")
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
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
                    return
                }
            }
            else {
                if let response = response as? HTTPURLResponse, response.statusCode == 409 {
                    let conflictError = NSError(domain: "goinfogame", code: 409, userInfo: [NSLocalizedDescriptionKey: "version mismatch"])
                    completion(.failure(conflictError))
                    return
                }
                
                do{
                    let decodedString = try String(data: data, encoding: .utf8)!
                    completion(.success(decodedString as! T))
                    return
                }
                catch {
                    print("Failed to decode the non JSON: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
            }
        }
        task.resume()
    }
}
