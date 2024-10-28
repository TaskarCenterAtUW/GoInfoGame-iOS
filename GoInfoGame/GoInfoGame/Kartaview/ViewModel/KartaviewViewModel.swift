//
//  KartaviewViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/10/24.
//

import Foundation
import UIKit

class KartaviewViewModel: ObservableObject {
    
    @Published var sequenceId: String?
    
    init() {}
    
    // Step 1: Create Sequence
    func createSequence() {
        let kartaViewAccessToken = "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7"
        let formData: [[String: Any]] =
        [["key": "access_token", "value": kartaViewAccessToken, "type": "text"]]
        
        
        ApiManager.shared.performRequest(to: .createKartaViewSequence(formData), setupType: .kartaview, modelType: SequenceModel.self) { result in
            switch result {
            case .success(let success):
                // Extract the sequenceId from the response model
                if  success.status.httpCode == 200 {
                    self.sequenceId = success.osv.sequence.id
                    print("Sequence created with ID: \(self.sequenceId)")
                    print("SEQUENCE CREATED ------> PROCEEDING TO UPLOAD PHOTO")
                    // Step 2: Upload Photo after receiving sequenceId
                   self.uploadPhoto(sequenceId: self.sequenceId!)
                }
            case .failure(let error):
                print("Failed to create sequence: \(error.localizedDescription)")
            }
        }
    }
    
    func uploadPhoto(sequenceId: String) {
        guard let image = UIImage(named: "food"), let imageData = imageToData(image: image) else {
            print("NO image found")
            return
        }
        
        let kartaViewAccessToken = "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7"
        
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
                "value": "17.45566375642105, 78.36914176316918",
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
              ]
            
        ]
        
        ApiManager.shared.performRequest(to: .uploadPhotoToKartaview(formData), setupType: .kartaview, modelType: UploadPhotoModel.self) { result in
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    print("PHOTO UPLOADED ----->>>> PROCEEDING TO FINISH UPLOAD")
                    self.finishUploading(sequenceId: sequenceId)
                }
            case .failure(let failure):
                print("FAILED")
            }
        }
    }
    
    func finishUploading(sequenceId: String) {
        let kartaViewAccessToken = "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7"
        
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
    }

    
    func imageToData(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 1.0)
    }
}
