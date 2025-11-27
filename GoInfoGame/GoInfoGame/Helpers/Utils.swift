//
//  Utils.swift
//  GoInfoGame
//
//  Created by Lakshmi Shweta Pochiraju on 29/12/23.
//

import Foundation
import SwiftUI

/// for navigationController pop view controllers
struct NavigationUtil {
    static func popToRootView(animated: Bool = false) {
        findNavigationController(viewController: UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.rootViewController)?.popToRootViewController(animated: animated)
    }
    
    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UITabBarController {
            return findNavigationController(viewController: navigationController.selectedViewController)
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        for childViewController in viewController.children {
            return findNavigationController(viewController: childViewController)
        }
        
        return nil
    }
}

struct Utilities {
    static func clearAllData() {
        @AppStorage("loggedIn") var loggedIn: Bool = false
        _ = KeychainManager.delete(key: "accessToken")
        _ = KeychainManager.delete(key: "refreshToken")
       // _ = KeychainManager.delete(key: "username")
        loggedIn = false
        UserProfileCache.shared.clearUserProfile()
        UserDefaults.standard.removeObject(forKey: APIConfiguration.environmentKey)
    }
    
    static func degreesToCardinalDirection(bearing: Double) -> String {
        let directions = ["North", "North East", "East", "South East", "South", "South West", "West", "Noth West", "North"]
        // Shift the bearing by 22.5 degrees (half the 45 degree sector size)
        // and then divide by 45 to get an index (0 to 8).
        let index = Int(((bearing + 22.5) / 45.0).truncatingRemainder(dividingBy: 8.0))
        return directions[index]
    }
}
