//
//  APIManager.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import Foundation
import Combine

// MARK: - APIRequest

protocol APIRequest {
    var urlRequest: URLRequest? { get }
}

// MARK: - APIRequest Extension

extension APIRequest {
    func setDefaultValues(urlRequest: URLRequest) -> URLRequest {
        var request: URLRequest = urlRequest
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let jwtAccessToken = KeychainManager.load(key: KeychainManager.Keys.accessToken.rawValue) {
            request.setValue("Bearer \(jwtAccessToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }
}

// MARK: - APIHaandler

protocol APIHandler {
    /**
     Fetches raw data from an API request asynchronously using Combine.

     This method performs a network request based on the given `APIRequest` and returns a `Future` publisher that either emits the retrieved `Data` or an `Error`.

     - Parameters:
       - request: The `APIRequest` object containing request details such as endpoint, headers, and parameters.

     - Returns:
       A `Future<Data, Error>` publisher that emits raw `Data` on success or an `Error` on failure.

     - Note: The caller is responsible for decoding the returned `Data` into the desired model.
     */
    func fetchData(from request: APIRequest) -> Future<Data, Error>
    
    func fetchData(from request: APIRequest) async throws -> (Data, URLResponse)
}

// MARK: - APIManager

class APIManager: APIHandler {
    /**
     A set to store Combine `AnyCancellable` instances.

     This property holds subscriptions to Combine publishers, ensuring they remain active for the lifecycle of the object.
     Automatically cancels subscriptions when the instance is deinitialized.

     - Note: Use this set to manage memory and prevent subscriptions from being prematurely deallocated.
     */
    private var cancellables: Set<AnyCancellable> = []

    func fetchData(from request: any APIRequest) -> Future<Data, Error> {
        return Future<Data, Error> { [weak self] promise in
            guard let self = self, let req = request.urlRequest else {
                return promise(.failure(NetworkError.invalidURLRequest))
            }

            URLSession.shared.dataTaskPublisher(for: req)
                .tryMap { (data, response) -> Data in
                    debugPrint("Response \n\(String(data: data, encoding: .utf8) ?? "")")
                    guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                        throw NetworkError.badNetwrok
                    }
                    return data
                }
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        promise(.failure(error))
                    case .finished:
                        break
                    }
                } receiveValue: { data in
                    promise(.success(data))
                }
                .store(in: &cancellables)
        }
    }
    
    func fetchData(from request: any APIRequest) async throws -> (Data, URLResponse) {
        guard let req = request.urlRequest else {
            throw NetworkError.invalidURLRequest
        }
        
        return try await URLSession.shared.data(for: req)
    }
}
