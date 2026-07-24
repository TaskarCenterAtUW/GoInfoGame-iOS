//
//  LiDARDetection.swift
//  GoInfoGame
//
//  Created by Prashamsa on 22/04/26.
//

import Foundation
import ARKit

class LiDARDetection {
    static let shared = LiDARDetection()
    
    /// Check if the current device supports LiDAR capability
    /// This uses dynamic ARKit capability detection which automatically supports future devices
    /// No hardcoded device models - will work with all current and future LiDAR-capable devices
    /// - Returns: true if device has LiDAR sensor, false otherwise
    func isLiDARSupported() -> Bool {
        // Check if ARKit is available on this device
        guard ARWorldTrackingConfiguration.isSupported else {
            return false
        }
        
        // Check for depth frame semantics support
        // This includes LiDAR and any future depth-sensing technology
        return ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) || ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
}
