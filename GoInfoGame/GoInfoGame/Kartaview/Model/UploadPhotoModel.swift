//
//  UploadPhotoModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/10/24.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let uploadPhotoModel = try? JSONDecoder().decode(UploadPhotoModel.self, from: jsonData)

import Foundation

// MARK: - UploadPhotoModel
struct UploadPhotoModel: Codable {
    let status: PhotoStatus
    let osv: PhotoOsv
}

// MARK: - Osv
struct PhotoOsv: Codable {
    let photo: Photo
}

// MARK: - Photo
struct Photo: Codable {
    let id, sequenceID, dateAdded, sequenceIndex: String
    let photoName, lat, lng: String

    enum CodingKeys: String, CodingKey {
        case id
        case sequenceID = "sequenceId"
        case dateAdded, sequenceIndex, photoName, lat, lng
    }
}

// MARK: - Status
struct PhotoStatus: Codable {
    let apiCode: Int
    let apiMessage: String
    let httpCode: Int
    let httpMessage: String
}

