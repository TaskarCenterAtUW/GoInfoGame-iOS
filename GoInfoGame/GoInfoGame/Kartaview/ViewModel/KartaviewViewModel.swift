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
    
    init(capturedImage: UIImage) {
        self.capturedImage = capturedImage
        
        locationManagerDelegate.locationManager.delegate = locationManagerDelegate
        locationManagerDelegate.locationManager.requestWhenInUseAuthorization()
        locationManagerDelegate.locationManager.startUpdatingLocation()
        locationManagerDelegate.locationManager.startUpdatingHeading()
        
        locationManagerDelegate.locationUpdateHandler = { [weak self] location in
            guard let self = self else { return }
            self.location = location
        }
        
        locationManagerDelegate.headingUpdateHandler = { [weak self] heading in
            guard let self = self else { return }
            self.heading = "\(heading)"
            locationManagerDelegate.locationManager.stopUpdatingHeading()
        }
    }
    
    // Step 1: Create Sequence
    func createSequence(completion: @escaping (String, Bool) -> ()) {
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
        
        let kartaViewAccessToken = "96aca5c4b80709fc6d9aced613b51905c0fbc37870640d7bdabede269165bde7"
        
        let latitude = location?.latitude.description ?? "0.0"
        let longitude = location?.longitude.description ?? "0.0"
        
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
        
        ApiManager.shared.performRequest(to: .uploadPhotoToKartaview(formData), setupType: .kartaview, modelType: UploadPhotoModel.self) { result in
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                    print("PHOTO UPLOADED ----->>>> PROCEEDING TO FINISH UPLOAD")
                    let imagePath = "https://api.openstreetcam.org/" + "\(success.osv.photo.path)/" + "th/\(success.osv.photo.photoName)"
                    self.finishUploading(path: imagePath,sequenceId: sequenceId, completion: completion)
                }
            case .failure(let failure):
                print("FAILED")
            }
        }
    }
    
    func finishUploading(path: String, sequenceId: String, completion: @escaping (String, Bool) -> ()) {
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
        
        ApiManager.shared.performRequest(to: .finshedUploadingToKartaview(formData), setupType: .kartaview, modelType: FinishUploadingModel.self) { result in
            switch result {
            case .success(let success):
                let status = success.status.httpCode
                if status == 200 {
                  print("PHOTO UPLOADED SUCCESSFULLY")
                    completion(path, true)
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
