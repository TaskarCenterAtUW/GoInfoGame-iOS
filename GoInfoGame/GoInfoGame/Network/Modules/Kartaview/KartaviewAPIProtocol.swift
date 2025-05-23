//
//  KartaviewAPIProtocol.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 24/05/25.
//

import Foundation

protocol KartaviewAPIProtocol {
    
    func createSequence(completion: @escaping (Result<SequenceModel, APIError>) -> Void)
    
    func uploadPhoto(imageData: Data, heading: String?,sequenceId: String, latitude: String, longitude: String, completion: @escaping (Result<UploadPhotoModel, APIError>) -> Void)
    
    func finishUploading(sequenceId: String, completion: @escaping (Result<FinishUploadingModel, APIError>) -> Void)
}
