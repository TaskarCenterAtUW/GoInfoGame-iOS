//
//  APIClient.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 15/04/24.
//

import Foundation

enum NetworkError: Error {
  case invalidURL
  case noData
  case decodingError
  case encodingError
  case badRequest(statusCode: Int)
}

class APIClient {

  private let baseURL: URL

  init(baseURL: URL) {
    self.baseURL = baseURL
  }

  func request<T: Decodable>(path: String, method: String = "GET", headers: [String: String]? = nil, body: Encodable? = nil, completion: @escaping (Result<T, Error>) -> Void) {
      guard let url = URL(string: baseURL.absoluteString + path) else {
        completion(.failure(NetworkError.invalidURL))
        return
      }

    var request = URLRequest(url: url)
    request.httpMethod = method

    headers?.forEach { key, value in
      request.addValue(value, forHTTPHeaderField: key)
    }

    if let body = body {
      do {
        request.httpBody = try JSONEncoder().encode(body)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      } catch {
        completion(.failure(NetworkError.encodingError))
        return
      }
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse else {
        completion(.failure(NetworkError.noData))
        return
      }

      let statusCode = httpResponse.statusCode

      if (200..<300).contains(statusCode) {
        guard let data = data else {
          completion(.failure(NetworkError.noData))
          return
        }

        do {
          let decodedData = try JSONDecoder().decode(T.self, from: data)
          completion(.success(decodedData))
        } catch {
          completion(.failure(NetworkError.decodingError))
        }
      } else {
        completion(.failure(NetworkError.badRequest(statusCode: statusCode)))
      }
    }.resume()
  }
}
