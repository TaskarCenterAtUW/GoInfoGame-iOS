//
//  NetworkManager.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import Foundation
import Combine
import SwiftUI

// MARK: - NetworkError

enum NetworkError: Error {
    case invalidURLRequest
    case decodingFailed
    case noData
    case badNetwrok
    case noNetwork
    case selfConversionError
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - NetworkHandler

protocol NetworkHandler {
    /**
     Fetches data from an API request and decodes it into a specified `Decodable` type using Combine.

     This method uses `Future<T, Error>` from the Combine framework to handle asynchronous network calls and decoding.

     - Generic Parameter:
       - `T`: A type that conforms to `Decodable`, representing the expected response model.

     - Parameters:
       - request: The `APIRequest` object containing request details such as endpoint, parameters, and headers.

     - Returns:
       A `Future<T, Error>` publisher that emits a decoded response of type `T` on success or an `Error` on failure.

     - Note: Ensure that `T` properly conforms to `Decodable` and matches the expected JSON response.
     */
    func fetchData<T: Decodable>( request: APIRequest) -> Future<T, Error>
    
    func fetchData<T: Decodable>( request: APIRequest) async throws -> T
}

// MARK: NetworkManager

class NetworkManager: NetworkHandler {
    /**
     A set to store Combine `AnyCancellable` instances.

     This property holds subscriptions to Combine publishers, ensuring they remain active for the lifecycle of the object.
     Automatically cancels subscriptions when the instance is deinitialized.

     - Note: Use this set to manage memory and prevent subscriptions from being prematurely deallocated.
     */
    private var cancellables: Set<AnyCancellable> = []

    let apiHandler: APIHandler
    let responseHandler: ResponseHandler
    let networkMonitor: NetworkMonitorHandler

    init(apiHandler: APIHandler = APIManager(),
         responseHandler: ResponseHandler = ResponseManager(),
         networkMonitor: NetworkMonitorHandler = NetworkMonitor.shared) {
        self.apiHandler = apiHandler
        self.responseHandler = responseHandler
        self.networkMonitor = networkMonitor
    }

    func fetchData<T: Decodable>(request: any APIRequest) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self else { return promise(.failure(NetworkError.badNetwrok)) }
            guard networkMonitor.status == true else { return promise(.failure(NetworkError.noNetwork)) }
            apiHandler.fetchData(from: request)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        promise(.failure(error))
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] data in
                    guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let code = jsonObject["code"] else {
                        return promise(.failure(NetworkError.decodingFailed))
                    }
                    if ((code as? Int) == 401 || (code as? String) == "401") &&
                        request.urlRequest?.url?.absoluteString.contains("refresh-token") == false &&
                        request.urlRequest?.url?.absoluteString.contains("authenticate") == false {
                        self?.refreshSession(promise: promise, request: request, type: T.self)
                    } else {
                        self?.responseHandler.decode(data, type: T.self, completion: { result in
                            switch result {
                            case .success(let value):
                                promise(.success(value))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        })
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    func fetchData<T>(request: any APIRequest) async throws -> T where T : Decodable {
        guard networkMonitor.status == true else {
            throw NetworkError.noNetwork
        }
        let (data, response) = try await apiHandler.fetchData(from: request)
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 401,
           httpResponse.url?.lastPathComponent.contains("refresh-token") == false,
           httpResponse.url?.lastPathComponent.contains("authenticate") == false {
            
            let tokenRefreshed = await TokenRefresher.shared.refreshTokenAsync()
            
            if tokenRefreshed {
                    // Retry request with new token
                    return try await fetchData(request: request)
                } else {
                    DispatchQueue.main.async {
                        if let window = UIApplication.window() {
                            Utilities.clearAllData()
                            window.rootViewController = UIHostingController(rootView: PosmLoginView())
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                NotificationCenter.default.post(name: Notification.Name("SessionExpired"), object: nil)
                            }
                        }
                    }
                    throw APIError(statusCode: 401, context: "Token refresh failed")
                }
        }
        let result =  try JSONDecoder().decode(T.self, from: data)
        return result
    }

    private func refreshSession<T: Decodable>(promise: @escaping (Result<T, Error>) -> Void,
                                              request: APIRequest,
                                              type: T.Type) {
        TokenRefresher.shared.refreshToken {[weak self] status, _ in
            guard let self = self else {
                return promise(.failure(NetworkError.badNetwrok))
            }

            if status {
                fetchData(request: request)
                    .sink(receiveCompletion: { comp in
                        switch comp {
                        case.finished:
                            break
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }, receiveValue: { data in
                        self.responseHandler.decode(data, type: T.self, completion: { result in
                            switch result {
                            case .success(let value):
                                promise(.success(value))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        })
                    })
                    .store(in: &cancellables)
            } else {
                debugPrint("Refresh token API failed.")
                Utilities.clearAllData()
                promise(.failure(NetworkError.badNetwrok))
            }
        }
    }
}
