//
//  PhotoUploadService.swift
//  GoInfoGame
//

import Foundation
import UIKit
import CoreLocation
import ImageIO
import UniformTypeIdentifiers

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

/// The compass direction the camera faced when a photo was taken (degrees from true north,
/// 0..<360). It is attached to the captured `UIImage`, written into the JPEG's EXIF when the
/// photo is queued on disk, read back when the queue loads it, and sent to Panoramax as
/// `GPSImgDirection` so the photo shows which way it looks.
enum PhotoHeading {

    /// Normalizes to 0..<360, or nil for an invalid (negative / non-finite) reading.
    static func normalized(_ degrees: Double?) -> Double? {
        guard let degrees, degrees.isFinite, degrees >= 0 else { return nil }
        let value = degrees.truncatingRemainder(dividingBy: 360)
        return value
    }

    /// Panoramax EXIF overrides, in the same form the Android app sends: a whole-degree
    /// rational and "T" for true north. Empty when the heading is unknown.
    static func overrideFields(for heading: Double?) -> [String: String] {
        guard let heading = normalized(heading) else { return [:] }
        let degrees = Int(heading.rounded()) % 360
        return [
            "override_Exif.GPSInfo.GPSImgDirection": "\(degrees)/1",
            "override_Exif.GPSInfo.GPSImgDirectionRef": "T"
        ]
    }

    /// JPEG data for an image, with its capture heading in the EXIF GPS block when it has one.
    static func jpegData(for image: UIImage, compressionQuality: CGFloat) -> Data? {
        guard let plain = image.jpegData(compressionQuality: compressionQuality) else { return nil }
        guard let heading = normalized(image.captureHeading),
              let source = CGImageSourceCreateWithData(plain as CFData, nil) else { return plain }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return plain
        }
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality,
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSImgDirection: heading,
                kCGImagePropertyGPSImgDirectionRef: "T"
            ]
        ]
        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return plain }
        return output as Data
    }

    /// The capture heading stored in a JPEG file's EXIF, if any.
    static func heading(inFileAt path: String) -> Double? {
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else { return nil }
        return normalized((gps[kCGImagePropertyGPSImgDirection] as? NSNumber)?.doubleValue)
    }

    /// Loads a queued photo from disk with its capture heading attached.
    static func loadImage(atPath path: String) -> UIImage? {
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        image.captureHeading = heading(inFileAt: path)
        return image
    }
}

private var captureHeadingKey: UInt8 = 0

extension UIImage {
    /// See `PhotoHeading`. Set by `CameraView` when the photo is taken.
    var captureHeading: Double? {
        get { (objc_getAssociatedObject(self, &captureHeadingKey) as? NSNumber)?.doubleValue }
        set { objc_setAssociatedObject(self, &captureHeadingKey, newValue.map { NSNumber(value: $0) }, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
    /// Which flow took the photo, so photos can be told apart and searched later.
    var source: Source? = nil
    /// The preset of a new element (e.g. "Bench"); its element id isn't known at upload time.
    var featureType: String? = nil

    enum Source: String {
        case quest
        case note
        case newFeature = "new_feature"
    }

    /// The current workspace. Element and question are added by the caller when the
    /// photo belongs to one.
    static func current(source: Source? = nil, elementId: String? = nil, question: String? = nil,
                        questId: Int? = nil, featureType: String? = nil) -> PhotoUploadContext {
        PhotoUploadContext(
            workspaceId: KeychainManager.load(key: "workspaceID"),
            elementId: elementId,
            question: question,
            questId: questId,
            source: source,
            featureType: featureType
        )
    }

    /// Panoramax semantics: one key/value pair per known field, empty ones left out.
    var semantics: [[String: String]] {
        [("workspace_id", workspaceId), ("element_id", elementId), ("quest_id", questId.map(String.init)),
         ("question", question), ("source", source?.rawValue), ("feature_type", featureType)]
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
    /// or new feature); the device location is used when it is unknown. `capturedAt` is when
    /// the photo was taken, which for a queued offline draft is earlier than the upload.
    static func upload(_ image: UIImage, coordinate: CLLocationCoordinate2D?, capturedAt: Date = Date(),
                       context: PhotoUploadContext = .current()) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { throw PanoramaxError.invalidImage }
        let location = try await photoLocation(coordinate)
        return try await makePanoramaxUploader().upload(imageData: imageData, coordinate: location,
                                                        capturedAt: capturedAt, heading: image.captureHeading,
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
