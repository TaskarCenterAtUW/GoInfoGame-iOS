//
//  SatelliteServerResponse.swift
//  GoInfoGame
//
//  Created by Prashamsa on 29/06/25.
//

import Foundation

// MARK: - SatelliteServer
struct SatelliteServer: Codable {
    let attribution: Attribution
    let description: String
    let extent: Extent
    let icon: String
    let id, name, type, url: String
}

// MARK: - Attribution
struct Attribution: Codable {
    let attributionRequired: Bool
    let text: String
    let url: String

    enum CodingKeys: String, CodingKey {
        case attributionRequired = "required"
        case text, url
    }
}

// MARK: - Extent
struct Extent: Codable {
    let maxZoom: Int
    let polygon: [[[Double]]]

    enum CodingKeys: String, CodingKey {
        case maxZoom = "max_zoom"
        case polygon
    }
}

typealias SatelliteServers = [SatelliteServer]
