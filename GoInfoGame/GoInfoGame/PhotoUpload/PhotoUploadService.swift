//
//  PhotoUploadService.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation

/// OSM tags that hold an element's photo URL. New photos go to Panoramax and are written
/// to `ext:street_images`. `ext:kartaview_url` is read-only: photos uploaded to KartaView
/// before the switch keep showing until the photo is replaced or removed, which clears it.
enum PhotoTag {
    /// Where every new photo's URL is written.
    static let streetImages = "ext:street_images"
    /// Legacy KartaView photos. Never written, only shown and cleared.
    static let kartaview = "ext:kartaview_url"

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

    /// A small version of a photo URL for previews. A Panoramax picture URL
    /// (`…/api/pictures/<id>/hd.jpg` or `sd.jpg`) becomes its 500px-wide `thumb.jpg`; any
    /// other URL, such as an old KartaView photo, is returned unchanged. The tag itself
    /// keeps the full-size URL.
    static func thumbnailURL(for urlString: String) -> String {
        guard var components = URLComponents(string: urlString) else { return urlString }
        var parts = components.path.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count >= 4,
              parts[parts.count - 3] == "pictures", parts[parts.count - 4] == "api",
              ["hd.jpg", "sd.jpg"].contains(parts[parts.count - 1]) else { return urlString }
        parts[parts.count - 1] = "thumb.jpg"
        components.path = parts.joined(separator: "/")
        return components.string ?? urlString
    }
}

/// Who and what a photo was taken for. Panoramax stores these as the picture's semantic
/// tags, so a photo can be traced back to its workspace, element and question later.
/// Semantics are public on the
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

    /// Replaceable so tests can point uploads at a stub instance with a test token.
    static var makePanoramaxUploader: () -> PanoramaxUploader = { PanoramaxUploader() }

    /// Uploads to Panoramax. `coordinate` is where the photo was taken (the element, note
    /// or new feature); the device location is used when it is unknown.
    static func upload(_ image: UIImage, coordinate: CLLocationCoordinate2D?,
                       context: PhotoUploadContext = .current()) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw PanoramaxError.invalidImage }
        let location = try await photoLocation(coordinate)
        return try await makePanoramaxUploader().upload(imageData: imageData, coordinate: location,
                                                        semantics: context.semantics)
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
