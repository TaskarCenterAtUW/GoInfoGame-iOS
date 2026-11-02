//
//  PhotoUploadService.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation

enum PhotoUploadProvider: String {
    case kartaview
    case panoramax

    var displayName: String {
        switch self {
        case .kartaview: return "Kartaview"
        case .panoramax: return "Panoramax"
        }
    }
}

/// The one place quest answers, notes and new features upload their photos. Returns the
/// hosted photo URL, which callers put in the element's tag or the note text.
enum PhotoUploadService {

    /// Set `PHOTO_UPLOAD_PROVIDER = panoramax` in Secrets.xcconfig to upload to Panoramax;
    /// anything else keeps KartaView.
    static var provider: PhotoUploadProvider = PhotoUploadProvider(
        rawValue: (Bundle.main.object(forInfoDictionaryKey: "PHOTO_UPLOAD_PROVIDER") as? String ?? "").lowercased()
    ) ?? .kartaview

    /// Replaceable so tests can point uploads at a stub instance with a test token.
    static var makePanoramaxUploader: () -> PanoramaxUploader = { PanoramaxUploader() }

    /// `coordinate` is where the photo was taken (the element, note or new feature); the
    /// device location is used when it is unknown. KartaView ignores it and uses the
    /// device location, as it always has.
    static func upload(_ image: UIImage, coordinate: CLLocationCoordinate2D?) async throws -> String {
        switch provider {
        case .kartaview:
            // KartaviewViewModel creates a CLLocationManager on init and immediately calls
            // requestWhenInUseAuthorization()/startUpdating*() — CoreLocation requires
            // those to happen on a thread with an active run loop (main), or the app-level
            // authorization handshake stalls. Only construction needs the hop; the network
            // upload itself is fine off the main thread.
            let viewModel = await MainActor.run { KartaviewViewModel(capturedImage: image) }
            return try await viewModel.uploadAsync()
        case .panoramax:
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw PanoramaxError.invalidImage }
            let location = try await photoLocation(coordinate)
            return try await makePanoramaxUploader().upload(imageData: imageData, coordinate: location)
        }
    }

    private static func photoLocation(_ coordinate: CLLocationCoordinate2D?) async throws -> CLLocationCoordinate2D {
        if let coordinate, CLLocationCoordinate2DIsValid(coordinate), coordinate.latitude != 0 || coordinate.longitude != 0 {
            return coordinate
        }
        let deviceLocation = await MainActor.run { CLLocationManager().location?.coordinate }
        guard let deviceLocation else { throw PanoramaxError.missingLocation }
        return deviceLocation
    }
}
