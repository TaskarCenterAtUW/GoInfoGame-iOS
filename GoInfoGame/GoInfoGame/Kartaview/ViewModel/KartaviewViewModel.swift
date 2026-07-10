//
//  KartaviewViewModel.swift
//  GoInfoGame
//
//  Created by Achyut Kumar M on 22/10/24.
//

import Foundation
import UIKit
import CoreLocation

class KartaviewViewModel: ObservableObject {
    
    @Published var sequenceId: String?
    
     var capturedImage: UIImage
    
    let locationManagerDelegate = LocationManagerDelegate()
    
    private var heading: String?
    
    private var location: CLLocationCoordinate2D?
    
    private let kartaViewAccessToken = Bundle.main.object(forInfoDictionaryKey: "KARTAVIEW_ACCESS_TOKEN") as? String ?? ""
    
    init(capturedImage: UIImage) {
        self.capturedImage = capturedImage
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.location = location
        }
        
        locationManagerDelegate.headingUpdateHandler = { [weak self] heading in
            guard let self = self else { return }
            self.heading = "\(heading)"
            locationManagerDelegate.stopUpdatingHeading()
        }
        
        locationManagerDelegate.requestLocationAuthorization()
        locationManagerDelegate.startUpdatingLocation()
        locationManagerDelegate.startUpdatingHeading()
    }
    
    // Step 1: Create Sequence
    func createSequence(completion: @escaping (String, Bool) -> ()) {
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
                    self.uploadPhoto(sequenceId: self.sequenceId!, completion: completion)
                }
            case .failure(let error):
                print("Failed to create sequence: \(error.localizedDescription)")
            }
        }
    }
    
    func uploadPhoto(sequenceId: String, completion: @escaping (String, Bool) -> ()) {
        guard let imageData = imageToData(image: capturedImage) else {
            print("NO image found")
            return
        }
        
        
        let latitude = location?.latitude.description ?? "0.0"
        let longitude = location?.longitude.description ?? "0.0"
        
        let formData: [[String: Any]] = [
            ["key": "access_token", "value": kartaViewAccessToken, "type": "text"],
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
                "value": kartaViewAccessToken,
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
        
        ApiManager.shared.performRequest(to: .uploadPhotoToKartaview(formData), setupType: .kartaview, modelType: UploadPhotoModel.self) { result in
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    print("PHOTO UPLOADED ----->>>> FINISHING SEQUENCE")
                    self.finishUploading(sequenceId: sequenceId, completion: completion)
                }
            case .failure(let failure):
                print("FAILED")
            }
        }
    }

    private func fetchPhotoLthUrl(sequenceId: String, sequenceIndex: String, attempt: Int = 1, maxAttempts: Int = 4, completion: @escaping (String?) -> Void) {
        let params: [[String: Any]] = [
            ["key": "access_token", "value": kartaViewAccessToken],
            ["key": "sequenceId", "value": sequenceId],
            ["key": "sequenceIndex", "value": sequenceIndex]
        ]
        ApiManager.shared.performRequest(to: .fetchPhotoUrlFromKartaview(params), setupType: .kartaviewV2, modelType: PhotoLookupResponse.self) { result in
            let lthUrl: String?
            switch result {
            case .success(let response):
                lthUrl = response.result?.data?.first?.imageLthUrl
            case .failure(let error):
                print("Photo lookup failed (attempt \(attempt)): \(error.localizedDescription)")
                lthUrl = nil
            }

            if let lthUrl = lthUrl {
                completion(lthUrl)
                return
            }

            guard attempt < maxAttempts else {
                completion(nil)
                return
            }
            // KartaView often needs a moment to index a freshly uploaded photo — back off and retry.
            let delaySeconds = pow(2.0, Double(attempt - 1))
            print("Photo not yet available — retrying in \(delaySeconds)s (attempt \(attempt + 1)/\(maxAttempts))")
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                self.fetchPhotoLthUrl(sequenceId: sequenceId, sequenceIndex: sequenceIndex, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
        }
    }
    
    func finishUploading(sequenceId: String, completion: @escaping (String, Bool) -> ()) {

        let formData: [[String: Any]] = [
             [
                "key": "sequenceId",
                "value": sequenceId,
                "type": "text"
              ],
              [
                "key": "access_token",
                "value": kartaViewAccessToken,
                "type": "text"
              ],
        ]

        ApiManager.shared.performRequest(to: .finshedUploadingToKartaview(formData), setupType: .kartaview, modelType: FinishUploadingModel.self) { result in
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    print("SEQUENCE FINISHED -----> FETCHING PHOTO URL")
                    self.fetchPhotoLthUrl(sequenceId: sequenceId, sequenceIndex: "1") { lthUrl in
                        guard let lthUrl = lthUrl else {
                            print("Failed to retrieve photo URL")
                            completion("An error occured", false)
                            return
                        }
                        print("PHOTO URL FETCHED: \(lthUrl)")
                        completion(lthUrl, true)
                    }
                }
            case .failure(let failure):
                print("FINISHING FAILED")
                completion("An error occured", false)
            }
        }
    }

    
    func imageToData(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 1.0)
    }
}
