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

    /// The OSM tag a photo uploaded to this provider is stored under.
    var tagKey: String {
        switch self {
        case .kartaview: return PhotoTag.kartaview
        case .panoramax: return PhotoTag.streetImages
        }
    }
}

/// OSM tags that hold an element's photo URL. Panoramax photos go in `ext:street_images`;
/// `ext:kartaview_url` is still read so photos taken before the switch keep showing.
enum PhotoTag {
    static let kartaview = "ext:kartaview_url"
    static let streetImages = "ext:street_images"

    /// Newest first: when an element has both, the street image wins.
    static let all = [streetImages, kartaview]

    /// The element's current photo URL, if it has one under any photo tag.
    static func existingURL(in tags: [String: String]?) -> String? {
        all.lazy.compactMap { tags?[$0] }.first { !$0.isEmpty }
    }

    /// The photo tags that currently hold a URL on the element.
    static func keysWithPhoto(in tags: [String: String]?) -> [String] {
        all.filter { !(tags?[$0] ?? "").isEmpty }
    }
}

/// Who and what a photo was taken for. Panoramax stores these as the picture's semantic
/// tags, so a photo can be traced back to its workspace, element and question later.
/// KartaView has nowhere to put them and ignores them. Semantics are public on the
/// picture, so nothing that identifies the user (such as their email) belongs here.
struct PhotoUploadContext: Equatable {
    var workspaceId: String?
    /// OSM-style id, e.g. "way/123" or "node/456".
    var elementId: String?
    var question: String?
    var questId: Int?

    /// The current workspace. Element and question are added by the caller when the
    /// photo belongs to one.
    static func current(elementId: String? = nil, question: String? = nil, questId: Int? = nil) -> PhotoUploadContext {
        PhotoUploadContext(
            workspaceId: KeychainManager.load(key: "workspaceID"),
            elementId: elementId,
            question: question,
            questId: questId
        )
    }

    /// Panoramax semantics: one key/value pair per known field, empty ones left out.
    var semantics: [[String: String]] {
        [("workspace_id", workspaceId), ("element_id", elementId), ("quest_id", questId.map(String.init)),
         ("question", question)]
            .compactMap { key, value in
                guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
                return ["key": key, "value": value]
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
    static func upload(_ image: UIImage, coordinate: CLLocationCoordinate2D?,
                       context: PhotoUploadContext = .current()) async throws -> String {
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
            return try await makePanoramaxUploader().upload(imageData: imageData, coordinate: location,
                                                            semantics: context.semantics)
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
