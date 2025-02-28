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
    
    
    func performRequestA<T: Decodable>(to endpoint: APIEndpoint, setupType: SetupType, modelType: T.Type, useJSON: Bool = true) async throws -> T {
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
              throw APIError.invalidURL
          }

          var request = URLRequest(url: url, timeoutInterval: Double.infinity)
          request.httpMethod = endpoint.method

          if let formData = endpoint.formData {
              let boundary = "Boundary-\(UUID().uuidString)"
              request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

              var body = Data()

              for param in formData {
                  guard let paramName = param["key"] as? String else {
                      print("Invalid parameter key")
                      continue
                  }

                  body.append("--\(boundary)\r\n".data(using: .utf8)!)

                  if let stringValue = param["value"] as? String {
                      body.append("Content-Disposition: form-data; name=\"\(paramName)\"\r\n\r\n".data(using: .utf8)!)
                      body.append("\(stringValue)\r\n".data(using: .utf8)!)
                  } else if let paramSrc = param["src"] as? Data {
                      do {
                          let filename = param["filename"] as? String ?? "image.jpeg"
                          let contentType = param["contentType"] as? String ?? "application/octet-stream"

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

              body.append("--\(boundary)--\r\n".data(using: .utf8)!)
              request.httpBody = body
          } else if let httpBody = endpoint.body {
              request.httpBody = httpBody
          }

          if let headers = endpoint.headers {
              for (key, value) in headers {
                  request.setValue(value, forHTTPHeaderField: key)
              }
          }

          let (data, response) = try await URLSession.shared.data(for: request)

          guard let httpResponse = response as? HTTPURLResponse else {
              throw APIError.noData
          }

          print("Response status code: \(httpResponse.statusCode)")

          guard 200...299 ~= httpResponse.statusCode else {
              if httpResponse.statusCode == 409 {
                  throw APIError.conflict
              } else {
                  let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown server error"
                  throw APIError.serverError(httpResponse.statusCode, errorMessage)
              }
          }

          if useJSON {
              do {
                  let decoder = JSONDecoder()
                  decoder.dateDecodingStrategy = .iso8601
                  return try decoder.decode(T.self, from: data)
              } catch {
                  print("Decoding error: \(error)")
                  if let jsonString = String(data: data, encoding: .utf8) {
                      print("JSON String that caused error: \(jsonString)")
                  }
                  throw APIError.decodingError(error)
              }
          } else {
              if T.self == String.self, let stringData = String(data: data, encoding: .utf8) as? T {
                  return stringData
              } else {
                  throw APIError.decodingError(NSError(domain: "goinfogame", code: 200, userInfo: [NSLocalizedDescriptionKey: "data is not a string"]))
              }
          }
      }
  
    
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
                    if data.isEmpty {
                        if T.self == Bool.self {
                            completion(.success(true as! T)) // Assuming success means `true` and this is for cloae changeset
                            return
                        } else {
                            completion(.failure(NSError(domain: "goinfogame", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected empty response"])))
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
                        let invalidJsonError = NSError(domain: "goinfogame", code: 200, userInfo: [NSLocalizedDescriptionKey: "not a valid JSON"])
                        completion(.failure(invalidJsonError))
                    } else {
                        let emptyJsonError = NSError(domain: "goinfogame", code: 200, userInfo: [NSLocalizedDescriptionKey: "empty JSON"])
                        completion(.failure(emptyJsonError))
                    }

                    return
                }
            }
            else {
                    if let response = response as? HTTPURLResponse {
                        switch response.statusCode {
                        case 409:
                            let conflictError = NSError(domain: "goinfogame", code: 409, userInfo: [NSLocalizedDescriptionKey: "version mismatch"])
                            completion(.failure(conflictError))

                        case 200:
                            do {
                                if let decodedString = String(data: data, encoding: .utf8) {
                                    completion(.success(decodedString as! T))
                                } else {
                                    completion(.failure(NSError(domain: "goinfogame", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode string"])))
                                }
                            } catch {
                                print("Failed to decode the non JSON: \(error.localizedDescription)")
                                completion(.failure(error))
                            }

                        default:
                            let unknownError = NSError(domain: "goinfogame", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected HTTP status code: \(response.statusCode)"])
                            completion(.failure(unknownError))
                        }
                    } else {
                        let noResponseError = NSError(domain: "goinfogame", code: -2, userInfo: [NSLocalizedDescriptionKey: "No valid HTTP response received"])
                        completion(.failure(noResponseError))
                    }
            }
        }
        task.resume()
    }
}
