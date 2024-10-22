//
//  KartaviewViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/10/24.
//

import Foundation

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
                    // Step 2: Upload Photo after receiving sequenceId
                  //  self.uploadPhoto(sequenceId: self.sequenceId!)
                }
            case .failure(let error):
                print("Failed to create sequence: \(error.localizedDescription)")
            }
        }
    }
    
//    func uploadPhoto(sequenceId: String) {
//        guard let image = UIImage(named: "your_image"), let imageData = imageToData(image: image) else {
//            print("No image found")
//            return
//        }
//        
//        let formData: [String: Any] = [
//            "sequenceId": sequenceId,
//            "image": imageData,
//            "accessToken": "your_access_token"
//        ]
//        
//        ApiManager.shared.performRequest(to: .uploadPhoto(formData), setupType: .kartaview, modelType: UploadPhotoResponseModel.self) { result in
//            switch result {
//            case .success(let success):
//                print("Photo uploaded successfully")
//                // Step 3: Call UploadingFinished API after photo upload
//                self.uploadingFinished(sequenceId: sequenceId)
//            case .failure(let error):
//                print("Photo upload failed: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func uploadingFinished(sequenceId: String) {
//        let body = ["sequenceId": sequenceId, "accessToken": "your_access_token"]
//        
//        ApiManager.shared.performRequest(to: .uploadingFinished(body), setupType: .kartaview, modelType: UploadFinishedResponseModel.self) { result in
//            switch result {
//            case .success(let success):
//                print("Sequence upload finished successfully")
//            case .failure(let error):
//                print("Failed to finish sequence upload: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    func imageToData(image: UIImage) -> Data? {
//        return image.jpegData(compressionQuality: 1.0)
//    }
}
