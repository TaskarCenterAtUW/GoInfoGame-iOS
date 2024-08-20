//
//  APIError.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 19/08/24.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case requestFailed(Error)
    case noData
    case decodingFailed(Error)
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed(let error):
            return "Request failed with error: \(error.localizedDescription)"
        case .noData:
            return "No data returned."
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
