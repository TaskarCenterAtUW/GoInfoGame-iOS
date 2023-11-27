//
//  OAuthError.swift
//  GoInfoGame
//
//  Created by Krishna Prakash on 20/11/23.
//

import Foundation

enum OAuthError: LocalizedError {
    case errorMessage(String)
    case badRedirectURL(String)
    case stateMismatch

    // MARK: - Computed Properties

    var errorDescription: String? {
        switch self {
        case let .errorMessage(message):
            return "OAuth error: \(message)"
        case .badRedirectURL:
            return "OAuth error: bad redirect URL"
        case .stateMismatch:
            return "OAuth error: state mismatch"
        }
    }
}
