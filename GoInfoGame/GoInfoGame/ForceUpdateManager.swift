//
//  ForceUpdateManager.swift
//  GoInfoGame
//
//  Created by Prashamsa on 13/10/25.
//

import Foundation
import Combine
import SwiftUI
import StoreKit

enum AppUpdateInfo {
    case noUpdate
    case softUpdate
    case forceUpdate
}

enum AppEnvironment {
    case sandbox // TestFlight or Xcode run
    case production // App Store release
    case unknown
}

class ForceUpdateManager: ObservableObject {
    
    private(set) var networkHandler: NetworkHandler
    @Published var appUpdateInfo: AppUpdateInfo = .noUpdate
    let updateCheckCompleted = PassthroughSubject<Void, Never>()
    private(set) var forceUpdateInfo: ForceUpdateResponse?
    private(set) var appEnvironment: AppEnvironment = .unknown
    
    init(networkHandler: NetworkHandler = NetworkManager()) {
        self.networkHandler = networkHandler
    }
    
    func checkForceUpdate() async throws {
        do {
            
//            let JsonString = """
//                {
//                  "ios": {
//                    "prod": {
//                      "min_required_version": "1.0.1",
//                      "latest_version": "1.0.3"
//                    },
//                    "stage": {
//                      "min_required_version": "1.0.3",
//                      "latest_version": "1.0.8"
//                    },
//                    "dev": {
//                      "min_required_version": "1.0.2",
//                      "latest_version": "1.0.7"
//                    }
//                  }
//                }
//                """
//            forceUpdateInfo = try JSONDecoder().decode(ForceUpdateResponse.self, from: JsonString.data(using: .utf8)!)
            forceUpdateInfo = try await networkHandler.fetchData(request: ForceUpdateRequest())
            appEnvironment = await getAppEnvironment()
            _ = validateForceUpdate()
        }
        catch {
            throw error
        }
    }
    
    func validateForceUpdate() -> AppUpdateInfo  {
        // latest version
        guard let appRunningVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            debugPrint("Bundle Short Version String not found")
            return .noUpdate
        }
        var newUpdateInfo: AppUpdateInfo = .noUpdate
        if let versionInfo = forceUpdateInfo?.ios.platformInfo[APIConfiguration.shared.environment.rawValue] {
            if appRunningVersion.compare(versionInfo.minRequiredVersion, options: .numeric) == .orderedAscending  {
                newUpdateInfo = .forceUpdate
            } else if appRunningVersion.compare(versionInfo.latestVersion, options: .numeric) == .orderedAscending {
                newUpdateInfo = .softUpdate
            }
        }
        
        let updateInfo = newUpdateInfo
        DispatchQueue.main.async { [weak self] in
            self?.appUpdateInfo = updateInfo
            self?.updateCheckCompleted.send()
        }
        return updateInfo
    }

    func getAppEnvironment() async -> AppEnvironment {
        
        do {
            // Retrieve the signed AppTransaction
            let result = try await AppTransaction.shared
            
            // Verify the transaction signature
            if case .verified(let appTransaction) = result {
                if appTransaction.environment == .xcode ||
                    appTransaction.environment == .sandbox {
                    return .sandbox
                } else if appTransaction.environment == .production {
                    return .production
                }
            }
        } catch {
            print("Error fetching AppTransaction: \(error)")
        }
        
        return .unknown
    }
}

class ForceUpdateRequest: APIRequest {
    var urlRequest: URLRequest? {
        guard let urlString = Bundle.main.infoDictionary?["APP_FORCE_UPDATE_URL"] as? String,
            let url = URL(string: urlString) else {
            return nil
        }
        let request = URLRequest(url: url)
        return request
    }
}

// MARK: - ForceUpdateResponse
struct ForceUpdateResponse: Codable {
    let ios: PlatformInfo
}

// MARK: - PlatformInfo
struct PlatformInfo: Codable {
    let platformInfo: [String: VersionInfo]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedInfo: [String: VersionInfo] = [:]
        
        // Iterate over all keys found in the JSON root
        for key in container.allKeys {
            // Decode the nested dictionary (VersionInfo) for each platform key
            let platformInfo = try container.decode(VersionInfo.self, forKey: key)
            decodedInfo[key.stringValue] = platformInfo
        }
        
        self.platformInfo = decodedInfo
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int?
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

// MARK: - Dev
struct VersionInfo: Codable {
    let minRequiredVersion, latestVersion: String

    enum CodingKeys: String, CodingKey {
        case minRequiredVersion = "min_required_version"
        case latestVersion = "latest_version"
    }
}
