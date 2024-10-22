//
//  SequenceModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/10/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let sequenceViewModel = try? JSONDecoder().decode(SequenceViewModel.self, from: jsonData)

import Foundation

// MARK: - SequenceViewModel
struct SequenceModel: Codable {
    let status: Status
    let osv: Osv
}

// MARK: - Osv
struct Osv: Codable {
    let sequence: Sequence
}

// MARK: - Sequence
struct Sequence: Codable {
    let id, userID, dateAdded, currentLat: String
    let currentLng: String
    let countryCode, stateCode: JSONNull?
    let status, imagesStatus, metaDataFilename: String
    let detectedSignsFilename, clientTotal, clientTotalDetails, obdInfo: JSONNull?
    let platformName, platformVersion, appVersion, track: JSONNull?
    let matchTrack, reviewed, changes, recognitions: JSONNull?
    let address, sequenceType, uploadSource, distance: JSONNull?
    let processingStatus, countActivePhotos: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "userId"
        case dateAdded, currentLat, currentLng, countryCode, stateCode, status, imagesStatus, metaDataFilename, detectedSignsFilename, clientTotal, clientTotalDetails, obdInfo, platformName, platformVersion, appVersion, track, matchTrack, reviewed, changes, recognitions, address, sequenceType, uploadSource, distance, processingStatus, countActivePhotos
    }
}

// MARK: - Status
struct Status: Codable {
    let apiCode: Int
    let apiMessage: String
    let httpCode: Int
    let httpMessage: String
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public var hashValue: Int {
            return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}
