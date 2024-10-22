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
        
       
        
        if let formData = endpoint.formData as? [[String: Any]] {
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
                } else if let paramSrc = param["src"] as? String {
                    // Handle file upload
                    do {
                        let fileData = try Data(contentsOf: URL(fileURLWithPath: paramSrc))
                        let contentType = param["contentType"] as? String ?? "application/octet-stream" // Default content type

                        // Append headers for file data
                        body.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(paramSrc)\"\r\n".data(using: .utf8)!)
                        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
                        body.append(fileData)
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
        
//        if let httpBody = endpoint.body {
//            request.httpBody = httpBody
//        }
        
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
    
    func performKartaviewRequest(to urlString: String, formData: [[String: Any]], completion: @escaping (Result<String, Error>) -> Void) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = ""

        do {
            for param in formData {
                if param["disabled"] != nil { continue }
                
                guard let paramName = param["key"] as? String else {
                    throw NSError(domain: "Invalid parameter key", code: 1, userInfo: nil)
                }
                
                body += "--\(boundary)\r\n"
                body += "Content-Disposition: form-data; name=\"\(paramName)\""
                
                if let contentType = param["contentType"] as? String {
                    body += "\r\nContent-Type: \(contentType)"
                }
                
                let paramType = param["type"] as! String
                if paramType == "text" {
                    guard let paramValue = param["value"] as? String else {
                        throw NSError(domain: "Invalid text parameter value", code: 2, userInfo: nil)
                    }
                    body += "\r\n\r\n\(paramValue)\r\n"
                } else if paramType == "file" {
                    guard let paramSrc = param["src"] as? String else {
                        throw NSError(domain: "Invalid file path", code: 3, userInfo: nil)
                    }
                    let fileData = try Data(contentsOf: URL(fileURLWithPath: paramSrc))
                    let fileContent = String(data: fileData, encoding: .utf8) ?? ""
                    body += "; filename=\"\(paramSrc)\"\r\n"
                        + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
                }
            }
            
            body += "--\(boundary)--\r\n"
            let postData = body.data(using: .utf8)

            guard let url = URL(string: urlString) else {
                throw NSError(domain: "Invalid URL", code: 4, userInfo: nil)
            }

            var request = URLRequest(url: url, timeoutInterval: Double.infinity)
            request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.httpBody = postData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "No data received", code: 5, userInfo: nil)))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    let statusError = NSError(domain: "Server error", code: httpResponse.statusCode, userInfo: nil)
                    completion(.failure(statusError))
                    return
                }
                
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to parse response"
                completion(.success(responseString))
            }
            
            task.resume()

        } catch {
            completion(.failure(error))
        }
    }
}
