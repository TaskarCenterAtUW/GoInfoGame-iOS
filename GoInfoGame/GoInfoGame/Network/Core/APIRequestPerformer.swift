//
//  APIRequestPerformer.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation
import SwiftUI

struct APIRequestPerformer {
    static func perform<T: Decodable>(request: APIRequest, config: APIRequestConfig, adapters:[APIRequestAdapter] = [], completion: @escaping (Result<T, APIError>) -> Void) {
        guard let url = URL(string: config.environment.baseURL.absoluteString + request.path) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url, timeoutInterval: Double.infinity)
        urlRequest.httpMethod = request.method
        
        var allHeaders: [String: String] = [:]

     
//        if let configWithHeaders = config as? APIRequestAdapter {
//            allHeaders.merge(configWithHeaders.headers) { _, new in new }
//        }
        for adapter in adapters {
            allHeaders.merge(adapter.headers) { _, new in new }
        }
     

        if let requestHeaders = request.headers {
            allHeaders.merge(requestHeaders) { _, new in new }
        }

        // Apply to URLRequest
        for (key, value) in allHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Handle multipart form-data
        if let formData = request.formData {
            let boundary = "Boundary-\(UUID().uuidString)"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
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
            urlRequest.httpBody = body
        } else if let rawBody = request.body {
            urlRequest.httpBody = rawBody
        }

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.custom(error.localizedDescription)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.custom("No valid HTTP response")))
                return
            }

            guard let data = data else {
                completion(.failure(.custom("No data returned")))
                return
            }

            switch httpResponse.statusCode {
            case 409: completion(.failure(.conflict)); return
            case 401: completion(.failure(.unauthorized)); return
            case 200...299: break
            default: completion(.failure(APIError(statusCode: httpResponse.statusCode))); return
            }

            if T.self == String.self {
                if let string = String(data: data, encoding: .utf8) {
                    completion(.success(string as! T))
                } else {
                    completion(.failure(.custom("Expected plain text response but decoding failed")))
                }
            } else if T.self == Bool.self, data.isEmpty {
                completion(.success(true as! T)) // Special case for empty body success
            } else {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decoded = try decoder.decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "Invalid JSON"
                    completion(.failure(.custom("Decoding failed: \(raw)")))
                }
            }



        }.resume()
    }
}

