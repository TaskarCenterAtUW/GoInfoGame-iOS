//
//  KartaviewAPIManager.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 21/05/25.
//

import Foundation

final class KartaviewAPIManager: KartaviewAPIProtocol {
    static let shared = KartaviewAPIManager()
    private let config = KartaviewRequestConfig()
    private var accessToken = "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7"
    
    private init() {}
    
    func createSequence(completion: @escaping (Result<SequenceModel, APIError>) -> Void) {
       
        let data: [[String: Any]] =
        [["key": "access_token", "value": accessToken, "type": "text"]]
        
        let request = APIRequest(
            path: "/sequence/",
            method: "POST",
            formData: data
        )

        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }
    
    func uploadPhoto(imageData: Data, heading: String?,sequenceId: String, latitude: String, longitude: String, completion: @escaping (Result<UploadPhotoModel, APIError>) -> Void) {
        
        let formData: [[String: Any]] = [
            ["key": "access_token", "value": "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7", "type": "text"],
            [
                "key": "sequenceId",
                "value": sequenceId,
                "type": "text"
            ],
            [
                "key": "sequenceIndex",
                "value": "1",
                "type": "text"
            ],
            [
                "key": "coordinate",
                "value": "\(latitude), \(longitude)",
                "type": "text"
            ],
            [
                "key": "access_token",
                "value": "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7",
                "type": "text"
            ],
            [
                "key": "photo",
                "src": imageData,
                "filename": "osmlogo.jpeg",
                "type": "file"
            ],
            [
                "key": "headers",
                "value": "\(heading ?? "0")",
                "type": "text"
            ]
            
        ]
        
         let request = APIRequest(
            path: "/upload/",
            method: "POST",
            formData: formData
        )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }

    func finishUploading(sequenceId: String, completion: @escaping (Result<FinishUploadingModel, APIError>) -> Void) {
        
        let formData: [[String: Any]] = [
            [
                "key": "sequenceId",
                "value": sequenceId,
                "type": "text"
            ],
            [
                "key": "access_token",
                "value": "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7",
                "type": "text"
            ],
        ]
        
        let request = APIRequest(
            path:  "/sequence/finished-uploading/",
            method: "POST",
            formData: formData
        )
        
        APIRequestPerformer.perform(request: request, config: config, completion: completion)
    }
    
}
