//
//  PhotoLookupResponse.swift
//  GoInfoGame
//

import Foundation

// MARK: - PhotoLookupResponse
struct PhotoLookupResponse: Codable {
    let result: PhotoLookupResult?
}

// MARK: - Result
struct PhotoLookupResult: Codable {
    let data: [PhotoLookupData]?
}

// MARK: - Data
struct PhotoLookupData: Codable {
    let imageLthUrl: String?
}
