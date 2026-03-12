//
//  APIError.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 19/08/24.
//

import Foundation

enum APIError: LocalizedError {
    // Local/Client-side errors
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingFailed(String)
    case custom(String)
    case noNetworkConnection

    // HTTP/Server-side errors
    case badRequest
    case unauthorized
    case forbidden
    case notFound(String)
    case conflict
    case serverError
    case deleted
    case unknown(code: Int, description: String)

    init(statusCode: Int, context: String? = nil) {
        switch statusCode {
        case 400: self = .badRequest
        case 401: self = .unauthorized
        case 403: self = .forbidden
        case 404: self = .notFound(context ?? "Item")
        case 409: self = .conflict
        case 410: self = .deleted
        case 500: self = .serverError
        default: self = .unknown(code: statusCode, description: HTTPURLResponse.localizedString(forStatusCode: statusCode))
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .noData:
            return "No data returned from the server."
        case .decodingFailed(let error):
            return "Failed to decode data: \(error)"
        case .badRequest:
            return "Bad Request: The request was invalid."
        case .unauthorized:
            return "Unauthorized: Please log in again."
        case .forbidden:
            return "Forbidden: You don’t have permission."
        case .notFound(let item):
            return "\(item) could not be found."
        case .conflict:
            return "Conflict: The data has changed on the server."
        case .serverError:
            return "Internal server error. Please try again later."
        case .unknown(_, let description):
            return "Unexpected error: \(description)"
        case .custom(let message):
            return message
        case .noNetworkConnection:
            return "No network connection."
        case .deleted:
            return "Deleted: The element is deleted from the server."
        }
    }
}


//enum APIError: Error {
//    case invalidURL
//    case requestFailed(Error)
//    case noData
//    case decodingFailed(Error)
//    case unknown
//    
//    var localizedDescription: String {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL."
//        case .requestFailed(let error):
//            return "Request failed with error: \(error.localizedDescription)"
//        case .noData:
//            return "No data returned."
//        case .decodingFailed(let error):
//            return "Failed to decode data: \(error.localizedDescription)"
//        case .unknown:
//            return "An unknown error occurred."
//        }
//    }
//}
