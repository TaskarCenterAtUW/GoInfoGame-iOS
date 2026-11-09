//
//  PanoramaxUploader.swift
//  GoInfoGame
//

import Foundation
import CoreLocation

enum PanoramaxError: LocalizedError, Equatable {
    case missingToken
    case missingLocation
    case invalidImage
    case invalidResponse
    case rejected(String)
    case server(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Panoramax token is not configured"
        case .missingLocation:
            return "Photo location is unknown"
        case .invalidImage:
            return "Failed to process the captured photo"
        case .invalidResponse:
            return "Unexpected response from Panoramax"
        case .rejected(let reason):
            return "Panoramax rejected the photo: \(reason)"
        case .server(let status, let message):
            return "Panoramax error \(status): \(message)"
        }
    }
}

/// Uploads one photo to a Panoramax instance and returns its hosted URL.
///
/// Flow (https://docs.panoramax.fr/backend/api/api/): create an upload set for a single
/// file, then upload the JPEG with its location and capture time. The upload set completes
/// on its own once that one file arrives. The picture id comes back immediately, but the
/// photo is only viewable once the server has finished blurring it (seconds to minutes).
struct PanoramaxUploader {

    let baseURL: String
    let token: String
    var session: URLSession = .shared

    /// Defaults to the instance and token of the app's current environment (dev, stage or
    /// prod), both set in Secrets.xcconfig.
    init(baseURL: String = APIConfiguration.shared.environment.panoramaxBaseURL,
         token: String = APIConfiguration.shared.environment.panoramaxToken,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    /// `semantics` are Panoramax semantic tags (`[["key": ..., "value": ...]]`) stored on the
    /// picture, e.g. from `PhotoUploadContext.semantics`.
    func upload(imageData: Data, coordinate: CLLocationCoordinate2D, capturedAt: Date = Date(),
                semantics: [[String: String]] = []) async throws -> String {
        guard !token.isEmpty else { throw PanoramaxError.missingToken }
        let uploadSetId = try await createUploadSet()
        let pictureId = try await uploadFile(imageData, to: uploadSetId, coordinate: coordinate,
                                             capturedAt: capturedAt, semantics: semantics)
        return pictureURL(for: pictureId)
    }

    func pictureURL(for pictureId: String) -> String {
        "\(baseURL)/api/pictures/\(pictureId)/hd.jpg"
    }

    // MARK: - Steps

    private func createUploadSet() async throws -> String {
        let payload: [String: Any] = [
            "title": "AVIV ScoutRoute",
            "estimated_nb_files": 1,
            // Every photo is its own upload: don't split it into sequences or drop it as a
            // duplicate of an earlier photo taken at the same spot.
            "no_split": true,
            "no_deduplication": true,
            "visibility": "anyone"
        ]
        var request = try makeRequest(path: "/api/upload_sets")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data = try await send(request, accepting: [200, 201])
        guard let uploadSet = try? JSONDecoder().decode(UploadSetResponse.self, from: data) else {
            throw PanoramaxError.invalidResponse
        }
        return uploadSet.id
    }

    private func uploadFile(_ imageData: Data, to uploadSetId: String, coordinate: CLLocationCoordinate2D,
                            capturedAt: Date, semantics: [[String: String]]) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try makeRequest(path: "/api/upload_sets/\(uploadSetId)/files")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Panoramax rejects photos without GPS and capture time, and our JPEG carries no
        // EXIF, so both are always sent as override fields.
        var body = Data()
        var fields = [
            "override_latitude": "\(coordinate.latitude)",
            "override_longitude": "\(coordinate.longitude)",
            "override_capture_time": ISO8601DateFormatter().string(from: capturedAt)
        ]
        if !semantics.isEmpty {
            let json = try JSONSerialization.data(withJSONObject: semantics, options: [.sortedKeys, .withoutEscapingSlashes])
            fields["semantics"] = String(decoding: json, as: UTF8.self)
        }
        for (name, value) in fields {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n")
        }
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(UUID().uuidString).jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let data = try await send(request, accepting: [200, 201, 202])
        guard let file = try? JSONDecoder().decode(UploadedFileResponse.self, from: data) else {
            throw PanoramaxError.invalidResponse
        }
        // A rejected photo still comes back as 202, with the reason in the body.
        if let rejected = file.rejected {
            throw PanoramaxError.rejected(rejected.message ?? rejected.reason)
        }
        guard let pictureId = file.pictureId else { throw PanoramaxError.invalidResponse }
        return pictureId
    }

    // MARK: - HTTP

    private func makeRequest(path: String) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else { throw PanoramaxError.invalidResponse }
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func send(_ request: URLRequest, accepting statuses: Set<Int>) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw PanoramaxError.invalidResponse }
        guard statuses.contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.message
                ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw PanoramaxError.server(status: http.statusCode, message: message)
        }
        return data
    }
}

// MARK: - Response models

private struct UploadSetResponse: Decodable {
    let id: String
}

private struct UploadedFileResponse: Decodable {
    let pictureId: String?
    let rejected: Rejection?

    struct Rejection: Decodable {
        let reason: String
        let message: String?
    }

    enum CodingKeys: String, CodingKey {
        case pictureId = "picture_id"
        case rejected
    }
}

private struct ErrorResponse: Decodable {
    let message: String
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
