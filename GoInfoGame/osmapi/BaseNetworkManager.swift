//
//  BaseNetworkManager.swift
//  osmapi
//
//  Created by Naresh Devalapally on 1/21/24.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case encodingError
}

class BaseNetworkManager {

    static let shared = BaseNetworkManager()
    
    func addOrSetHeaders(header:String, value:String){
        self.headers[header] = value
    }
    private var headers:[String: String] = [:]
    private init() {}

    func fetchData<T: Decodable>(url: URL, completion: @escaping (Result<T, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { key,value in
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        URLSession.shared.dataTask(with:request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NetworkError.invalidURL))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let theDecoder = JSONDecoder()
                theDecoder.dateDecodingStrategy = .iso8601
                let decodedData = try theDecoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                print(String(data: data, encoding: .utf8)!)
                print(error)
                completion(.failure(NetworkError.decodingError))
            }
        }.resume()
    }
    
    func postData<T: Decodable, U: Encodable>(
            url: URL,
            method: String = "POST",
            body: U,
            headers: [String: String]? = nil,
            expectEmpty: Bool = false,
            completion: @escaping (Result<T, Error>) -> Void
        ) {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            // Add additional headers if provided for this request only
            headers?.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }
            self.headers.forEach { key,value in
                request.addValue(value, forHTTPHeaderField: key)
            }

            do {
                // Encode the request body
                let jsonData = try JSONEncoder().encode(body)
                request.httpBody = jsonData

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        completion(.failure(NetworkError.invalidURL))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(NetworkError.noData))
                        return
                    }
                    if data.isEmpty && expectEmpty {
                        completion(.success(true as! T))
                        return
                    }

                    do {
                        // Decode the response
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decodedData))
                    } catch {
                        completion(.failure(NetworkError.decodingError))
                    }
                }.resume()
            } catch {
                completion(.failure(NetworkError.encodingError))
            }
        }
    
    /// Posts XML data 
    func postData<T: Decodable, U: OSMPayload>(
            url: URL,
            method: String = "POST",
            body: U,
            headers: [String: String]? = nil,
            completion: @escaping (Result<T, Error>) -> Void
        ) {
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.addValue("application/xml", forHTTPHeaderField: "Content-Type")

            // Add additional headers if provided for this request only
            headers?.forEach { key, value in
                request.addValue(value, forHTTPHeaderField: key)
            }
            self.headers.forEach { key,value in
                request.addValue(value, forHTTPHeaderField: key)
            }

            do {
                // Encode the request body
                let data = body.toPayload()
                request.httpBody = data.data(using: .utf8)

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                        completion(.failure(NetworkError.invalidURL))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(NetworkError.noData))
                        return
                    }

                    do {
                        // Decode the response
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(decodedData))
                    } catch {
                        completion(.failure(NetworkError.decodingError))
                    }
                }.resume()
            } catch {
                completion(.failure(NetworkError.encodingError))
            }
        }
}
