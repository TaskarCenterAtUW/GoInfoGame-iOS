//
//  JWTDecoder.swift
//  GoInfoGame
//

import Foundation

enum JWTDecoder {
    static func claims(fromToken token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            debugPrint("Invalid JWT format.")
            return nil
        }

        let payloadSegment = segments[1]
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainingLength = base64.count % 4
        if remainingLength > 0 {
            base64 += String(repeating: "=", count: 4 - remainingLength)
        }

        guard let data = Data(base64Encoded: base64) else {
            debugPrint("Could not Base64URL decode the JWT payload.")
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            debugPrint("Error parsing JWT payload JSON: \(error)")
            return nil
        }
    }

    static func subject(fromToken token: String) -> String? {
        claims(fromToken: token)?["sub"] as? String
    }
}
