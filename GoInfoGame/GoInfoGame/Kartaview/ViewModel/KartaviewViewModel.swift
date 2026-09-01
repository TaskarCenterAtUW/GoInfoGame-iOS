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
        
        
        ApiManager.shared.performRequest(to: .createKartaViewSequence(formData), setupType: .kartaview, modelType: SequenceModel.self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                // Extract the sequenceId from the response model
                if  success.status.httpCode == 200 {
                    self.sequenceId = success.osv.sequence.id
                    print("Sequence created with ID: \(self.sequenceId ?? "")")
                    print("SEQUENCE CREATED ------> PROCEEDING TO UPLOAD PHOTO")
                    // Step 2: Upload Photo after receiving sequenceId
                    self.uploadPhoto(sequenceId: self.sequenceId!, completion: completion)
                } else {
                    completion("Failed to create Kartaview sequence", false)
                }
            case .failure(let error):
                print("Failed to create sequence: \(error.localizedDescription)")
                completion(error.localizedDescription, false)
            }
        }
    }

    func uploadPhoto(sequenceId: String, completion: @escaping (String, Bool) -> ()) {
        guard let imageData = imageToData(image: capturedImage) else {
            print("NO image found")
            completion("Failed to process the captured photo", false)
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
        
        ApiManager.shared.performRequest(to: .uploadPhotoToKartaview(formData), setupType: .kartaview, modelType: UploadPhotoModel.self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    print("PHOTO UPLOADED ----->>>> FINISHING SEQUENCE")
                    self.finishUploading(photoId: success.osv.photo.id, sequenceId: sequenceId, completion: completion)
                } else {
                    completion("Failed to upload photo to Kartaview", false)
                }
            case .failure(let failure):
                print("FAILED")
                completion(failure.localizedDescription, false)
            }
        }
    }

    func finishUploading(photoId: String, sequenceId: String, completion: @escaping (String, Bool) -> ()) {

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

        ApiManager.shared.performRequest(to: .finshedUploadingToKartaview(formData), setupType: .kartaview, modelType: FinishUploadingModel.self) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    // Look the photo up by its own id — the authoritative per-photo
                    // identifier, returned in the upload response — to get KartaView's
                    // own hosted URL. Bounded to a couple of quick attempts; if it's
                    // still not queryable, this is a genuine failure (no locally-guessed
                    // URL is substituted) and is reported/logged as such.
                    self.fetchHostedPhotoUrl(photoId: photoId) { hostedUrl in
                        guard let hostedUrl = hostedUrl else {
                            print("KARTAVIEW PHOTO URL LOOKUP FAILED ----->>>> photoId: \(photoId), sequenceId: \(sequenceId)")
                            completion("Failed to retrieve photo URL", false)
                            return
                        }
                        print("PHOTO UPLOADED SUCCESSFULLY: \(hostedUrl)")
                        completion(hostedUrl, true)
                    }
                } else {
                    completion("Failed to finish Kartaview upload", false)
                }
            case .failure(let failure):
                print("FINISHING FAILED")
                completion("An error occured", false)
            }
        }
    }

    /// Looks up the hosted URL for a photo by its own id (not sequenceId+sequenceIndex —
    /// that composite lookup was the source of the earlier "Failed to retrieve photo URL"
    /// failures). Bounded retry budget; returns nil (never throws) if KartaView still
    /// can't produce a URL, so the caller can report/log a genuine failure rather than
    /// silently guessing a URL that may or may not be correct.
    private func fetchHostedPhotoUrl(photoId: String, attempt: Int = 1, maxAttempts: Int = 2, completion: @escaping (String?) -> Void) {
        ApiManager.shared.performRequest(to: .fetchPhotoUrlFromKartaview(photoId, kartaViewAccessToken), setupType: .kartaviewV2, modelType: PhotoLookupResponse.self) { [weak self] result in
            guard let self = self else { return }
            if case .success(let response) = result, let url = response.result?.data?.imageLthUrl {
                completion(url)
                return
            }
            if case .failure(let error) = result {
                print("Photo id lookup failed (attempt \(attempt)/\(maxAttempts)) for photoId \(photoId): \(error.localizedDescription)")
            } else {
                print("Photo id lookup returned no URL (attempt \(attempt)/\(maxAttempts)) for photoId \(photoId)")
            }
            guard attempt < maxAttempts else {
                completion(nil)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.fetchHostedPhotoUrl(photoId: photoId, attempt: attempt + 1, maxAttempts: maxAttempts, completion: completion)
            }
        }
    }


    func imageToData(image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: 1.0)
    }

    /// Runs the full create-sequence → upload-photo → finish → fetch-url chain and returns the hosted photo URL.
    func uploadAsync() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            createSequence { result, success in
                if success {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(domain: "KartaviewUpload", code: 0, userInfo: [NSLocalizedDescriptionKey: result]))
                }
            }
        }
    }
}
